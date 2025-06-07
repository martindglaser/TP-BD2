USE [TP-BD2]
GO

CREATE PROCEDURE sp_alta_prospecto
    @tipo_documento VARCHAR(50),
    @nro_documento VARCHAR(8),
    @nombre VARCHAR(50),
    @apellido VARCHAR(50),
    @email VARCHAR(100) = NULL,
    @fecha_nacimiento DATE = NULL
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validaciones básicas
        IF LEN(@nro_documento) <> 8 OR ISNUMERIC(@nro_documento) = 0
            THROW 50001, 'Número de documento inválido.', 1;

        IF @fecha_nacimiento IS NOT NULL AND DATEDIFF(YEAR, @fecha_nacimiento, GETDATE()) < 18
            THROW 50002, 'La persona debe ser mayor de 18 años.', 1;

        -- Insertar en Persona y Prospecto
        INSERT INTO Persona VALUES(@tipo_documento, @nro_documento, @fecha_nacimiento, @email, 'Prospecto', @nombre, @apellido, 'Prospecto');
        INSERT INTO Prospecto VALUES(@tipo_documento, @nro_documento, (SELECT ISNULL(MAX(id_prospecto), 0)+1 FROM Prospecto));

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END
GO

-- Procedimiento: Alta de Servicio
CREATE PROCEDURE sp_alta_servicio
    @id_cliente INT,
    @id_tipo_servicio INT,
    @telefono VARCHAR(20),
    @calle VARCHAR(100),
    @numero INT,
    @piso INT,
    @depto INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @requiere_telefono BIT = CASE WHEN @id_tipo_servicio IN (1,3) THEN 1 ELSE 0 END;
        IF @requiere_telefono = 1 AND (@telefono IS NULL OR LEN(@telefono) = 0)
            THROW 50003, 'El servicio requiere teléfono.', 1;

        IF @id_tipo_servicio = 2 AND @telefono IS NOT NULL
            SET @telefono = NULL;

        DECLARE @id_servicio INT = (SELECT ISNULL(MAX(id_servicio), 0)+1 FROM Servicio);
        INSERT INTO Servicio VALUES(@id_servicio, @id_tipo_servicio, @telefono, @calle, @numero, @piso, @depto, GETDATE(), 'Activo');
        INSERT INTO Cientes_Servicios VALUES(@id_cliente, @id_servicio);

        -- Actualizar estado de Persona a Activo si estaba Inactivo o Prospecto
        UPDATE Persona
        SET estado = 'Activo', cliente_o_prospecto = 'Cliente'
        WHERE (SELECT tipo_documento FROM Cliente WHERE id_cliente = @id_cliente) = tipo_documento
        AND (SELECT nro_documento FROM Cliente WHERE id_cliente = @id_cliente) = nro_documento;

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END
GO

-- Procedimiento: Crear nuevo Ticket
CREATE PROCEDURE sp_crear_ticket
    @id_cliente INT,
    @id_tipo_ticket INT,
    @id_empleado INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS(SELECT 1 FROM Empleado WHERE id_empleado = @id_empleado AND estado = 'Activo')
            THROW 50004, 'El empleado no está activo.', 1;

        DECLARE @id_ticket INT = (SELECT ISNULL(MAX(id_ticket),0)+1 FROM Ticket);
        INSERT INTO Ticket(id_ticket, id_estado, id_tipo_ticket, id_empleado) VALUES
        (@id_ticket, 1, @id_tipo_ticket, @id_empleado);

        INSERT INTO Clientes_Tickets VALUES(@id_cliente, @id_ticket);

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END
GO

-- Trigger: Actualizar estado de Cliente al inactivar último servicio
CREATE TRIGGER trg_inactivar_servicio_cliente
ON Servicio
AFTER UPDATE
AS
BEGIN
    IF UPDATE(estado)
    BEGIN
        DECLARE @id_servicio INT, @id_cliente INT;
        SELECT @id_servicio = id_servicio FROM inserted;
        SELECT @id_cliente = id_cliente FROM Cientes_Servicios WHERE id_servicio = @id_servicio;

        -- Si todos los servicios del cliente están inactivos
        IF NOT EXISTS (
            SELECT 1 FROM Servicio S
            JOIN Cientes_Servicios CS ON S.id_servicio = CS.id_servicio
            WHERE CS.id_cliente = @id_cliente AND S.estado = 'Activo'
        )
        BEGIN
            DECLARE @doc VARCHAR(5), @nro VARCHAR(8);
            SELECT @doc = tipo_documento, @nro = nro_documento FROM Cliente WHERE id_cliente = @id_cliente;
            UPDATE Persona SET estado = 'Inactivo' WHERE tipo_documento = @doc AND nro_documento = @nro;
        END
    END
END
GO

-- Trigger: Registrar fecha de resolución y envío de email
CREATE TRIGGER trg_ticket_estado_resuelto
ON Ticket
AFTER UPDATE
AS
BEGIN
    IF UPDATE(id_estado)
    BEGIN
        UPDATE T
        SET fecha_hora_resolucion = GETDATE()
        FROM Ticket T
        JOIN inserted I ON T.id_ticket = I.id_ticket
        WHERE I.id_estado = 4;
		

		INSERT INTO Email_Queue(destinatario, asunto, cuerpo)
		SELECT P.email,
			   'Cambio de estado de Ticket',
			   CONCAT('El ticket ', I.id_ticket, ' ha cambiado su estado a RESUELTO.')
		FROM inserted I
		JOIN Clientes_Tickets CT ON I.id_ticket = CT.id_ticket
		JOIN Cliente C ON CT.id_cliente = C.id_cliente
		JOIN Persona P ON P.tipo_documento = C.tipo_documento AND P.nro_documento = C.nro_documento;

    END
END
GO



CREATE PROCEDURE sp_cambiar_estado_ticket
    @id_ticket INT,
    @nuevo_estado INT,
    @id_usuario INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @estado_actual INT, @estado_cerrado INT = 5;

        -- Obtener estado actual
        SELECT @estado_actual = id_estado FROM Ticket WHERE id_ticket = @id_ticket;

        -- Validar existencia
        IF @estado_actual IS NULL
            THROW 50000, 'El ticket no existe.', 1;

        -- Validar que el ticket no esté cerrado
        IF @estado_actual = @estado_cerrado
            THROW 50010, 'No se puede modificar un ticket cerrado.', 1;

        -- Validar que el usuario sea el dueño del ticket
        IF NOT EXISTS (
            SELECT 1 FROM Ticket WHERE id_ticket = @id_ticket AND id_empleado = @id_usuario
        )
            THROW 50012, 'Solo el dueño del ticket puede modificarlo.', 1;

        -- Validar transición permitida (sin tabla)
        IF (
            (@estado_actual = 1 AND @nuevo_estado NOT IN (2)) OR
            (@estado_actual = 2 AND @nuevo_estado NOT IN (3, 4)) OR
            (@estado_actual = 3 AND @nuevo_estado NOT IN (2)) OR
            (@estado_actual = 4 AND @nuevo_estado NOT IN (5))
        )
            THROW 50011, 'Transición de estado no permitida.', 1;

        -- Realizar el cambio
        UPDATE Ticket
        SET id_estado = @nuevo_estado,
            fecha_hora_resolucion = CASE WHEN @nuevo_estado = 4 THEN GETDATE() ELSE fecha_hora_resolucion END
        WHERE id_ticket = @id_ticket;

        -- Insertar email en Email_Queue
        INSERT INTO Email_Queue (destinatario, asunto, cuerpo)
        SELECT
            P.email,
            'Cambio de estado de Ticket',
            CONCAT('El ticket ', T.id_ticket, ' ha cambiado su estado a ', ET.descripcion)
        FROM Ticket T
        JOIN Clientes_Tickets CT ON T.id_ticket = CT.id_ticket
        JOIN Cliente C ON CT.id_cliente = C.id_cliente
        JOIN Persona P ON C.tipo_documento = P.tipo_documento AND C.nro_documento = P.nro_documento
        JOIN Estado_Ticket ET ON ET.id_estado = @nuevo_estado
        WHERE T.id_ticket = @id_ticket;

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END
GO




CREATE PROCEDURE sp_reasignar_ticket
    @id_ticket INT,
    @nuevo_empleado INT,
    @usuario_actual INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @estado INT, @dueño_actual INT;

        SELECT @estado = id_estado, @dueño_actual = id_empleado
        FROM Ticket WHERE id_ticket = @id_ticket;

        IF @estado = 5
            THROW 50020, 'No se puede reasignar un ticket cerrado.', 1;

        IF @dueño_actual <> @usuario_actual
            THROW 50021, 'Solo el dueño del ticket puede reasignarlo.', 1;

        IF NOT EXISTS (SELECT 1 FROM Empleado WHERE id_empleado = @nuevo_empleado AND estado = 'Activo')
            THROW 50022, 'El nuevo empleado no está activo.', 1;

        UPDATE Ticket SET id_empleado = @nuevo_empleado
        WHERE id_ticket = @id_ticket;

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END
GO



CREATE TRIGGER trg_validar_modificaciones_persona
ON Persona
INSTEAD OF UPDATE
AS
BEGIN
    -- Solo permitir cambios si sigue siendo prospecto
    IF EXISTS (
        SELECT 1 FROM inserted I
        JOIN deleted D ON I.tipo_documento = D.tipo_documento AND I.nro_documento = D.nro_documento
        WHERE D.cliente_o_prospecto <> 'Prospecto' AND (
              I.nombre <> D.nombre OR
              I.apellido <> D.apellido OR
              I.tipo_documento <> D.tipo_documento OR
              I.nro_documento <> D.nro_documento OR
              I.fecha_nacimiento <> D.fecha_nacimiento
        )
    )
    BEGIN
        THROW 50030, 'Solo se pueden modificar estos datos cuando la persona es Prospecto.', 1;
    END

    -- Si pasa la validación, aplicar el update real
    UPDATE P
    SET
        nombre = I.nombre,
        apellido = I.apellido,
        tipo_documento = I.tipo_documento,
        nro_documento = I.nro_documento,
        fecha_nacimiento = I.fecha_nacimiento,
        email = I.email,
        estado = I.estado,
        cliente_o_prospecto = I.cliente_o_prospecto
    FROM Persona P
    JOIN inserted I ON P.tipo_documento = I.tipo_documento AND P.nro_documento = I.nro_documento;
END
GO
