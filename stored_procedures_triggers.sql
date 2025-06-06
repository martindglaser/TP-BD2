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
		-- LOGICA DE ENVIO DE EMAIL --

    END
END
GO
