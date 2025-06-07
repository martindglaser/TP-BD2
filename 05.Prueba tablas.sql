USE [TP-BD2];
GO


-- SCRIPT DE PRUEBAS - TRABAJO FINAL BD2



-- CASO 1: Alta de nuevo prospecto

SELECT * FROM Persona WHERE tipo_documento = 'DNI' AND nro_documento = '33445566';

EXEC sp_alta_prospecto
    @tipo_documento = 'DNI',
    @nro_documento = '33445566',
    @nombre = 'Laura',
    @apellido = 'Martinez',
    @email = 'laura.martinez@example.com',
    @fecha_nacimiento = '1995-07-15';

SELECT * FROM Persona WHERE tipo_documento = 'DNI' AND nro_documento = '33445566';
SELECT * FROM Prospecto WHERE tipo_documento = 'DNI' AND nro_documento = '33445566';


-- CASO 2: Alta prospecto con datos inválidos (menor de edad)
BEGIN TRY
    EXEC sp_alta_prospecto
        @tipo_documento = 'DNI',
        @nro_documento = '44556677',
        @nombre = 'Carlos',
        @apellido = 'Suarez',
        @email = 'carlos.suarez@example.com',
        @fecha_nacimiento = '2010-01-01';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrorCode, ERROR_MESSAGE() AS ErrorMessage;
END CATCH


-- CASO 3: Alta servicio a prospecto (pasa a Activo)

INSERT INTO Cliente (tipo_documento, nro_documento, id_cliente)
VALUES ('DNI', '33445566', 3);

SELECT * FROM Persona WHERE tipo_documento = 'DNI' AND nro_documento = '33445566';

EXEC sp_alta_servicio
    @id_cliente = 3,
    @id_tipo_servicio = 2,
    @telefono = NULL,
    @calle = 'Calle Nueva',
    @numero = 1234,
    @piso = 1,
    @depto = 2;

SELECT * FROM Persona WHERE tipo_documento = 'DNI' AND nro_documento = '33445566';
SELECT * FROM Cientes_Servicios WHERE id_cliente = 3;


-- CASO 4: Alta servicio a cliente inactivo (cambiará a Activo)

SELECT * FROM Persona WHERE tipo_documento = 'DNI' AND nro_documento = '87654321';

EXEC sp_alta_servicio
    @id_cliente = 2,
    @id_tipo_servicio = 1,
    @telefono = '1122233344',
    @calle = 'Av Siempreviva',
    @numero = 100,
    @piso = 2,
    @depto = 3;

SELECT * FROM Persona WHERE tipo_documento = 'DNI' AND nro_documento = '87654321';
SELECT * FROM Cientes_Servicios WHERE id_cliente = 2;


-- CASO 5: Intentar crear servicio a prospecto sin email o sin fecha de nacimiento (debe dar error ahora que lo agregaste)

-- Damos de alta prospecto SIN email y SIN fecha nacimiento
EXEC sp_alta_prospecto
    @tipo_documento = 'DNI',
    @nro_documento = '55667788',
    @nombre = 'Ernesto',
    @apellido = 'Lopez',
    @email = NULL,
    @fecha_nacimiento = NULL;

-- Lo pasamos a Cliente
INSERT INTO Cliente (tipo_documento, nro_documento, id_cliente)
VALUES ('DNI', '55667788', 4);

-- Intentamos crear servicio → debería dar error
BEGIN TRY
    EXEC sp_alta_servicio
        @id_cliente = 4,
        @id_tipo_servicio = 1,
        @telefono = '1133445566',
        @calle = 'Calle Prueba',
        @numero = 999,
        @piso = 0,
        @depto = 0;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrorCode, ERROR_MESSAGE() AS ErrorMessage;
END CATCH


-- CASO 6: Inactivar último servicio de cliente (queda Inactivo)

UPDATE Servicio SET estado = 'Activo' WHERE id_servicio = 3;

SELECT * FROM Persona WHERE tipo_documento = 'DNI' AND nro_documento = '87654321';
SELECT * FROM Servicio WHERE id_servicio = 3;

UPDATE Servicio SET estado = 'Inactivo' WHERE id_servicio = 3;

SELECT * FROM Persona WHERE tipo_documento = 'DNI' AND nro_documento = '87654321';


-- CASO 7: Inactivar servicio con más de un servicio activo

UPDATE Servicio SET estado = 'Activo' WHERE id_servicio = 1;

SELECT * FROM Persona WHERE tipo_documento = 'DNI' AND nro_documento = '12345678';
SELECT * FROM Servicio WHERE id_servicio = 1;

UPDATE Servicio SET estado = 'Inactivo' WHERE id_servicio = 1;

SELECT * FROM Persona WHERE tipo_documento = 'DNI' AND nro_documento = '12345678';


-- CASO 8: Crear nuevo ticket

SELECT * FROM Ticket;

EXEC sp_crear_ticket
    @id_cliente = 1,
    @id_tipo_ticket = 1,
    @id_empleado = 1;

SELECT * FROM Ticket;
SELECT * FROM Clientes_Tickets;


-- CASO 9: Cambio de estado permitido

EXEC sp_cambiar_estado_ticket
    @id_ticket = 1,
    @nuevo_estado = 2,
    @id_usuario = 1;

SELECT * FROM Ticket WHERE id_ticket = 1;
SELECT * FROM Email_Queue;


-- CASO 10: Cambio de estado a Resuelto

EXEC sp_cambiar_estado_ticket
    @id_ticket = 1,
    @nuevo_estado = 4,
    @id_usuario = 1;

SELECT * FROM Ticket WHERE id_ticket = 1;
SELECT * FROM Email_Queue;


-- CASO 11: Cambio de estado no permitido

BEGIN TRY
    EXEC sp_cambiar_estado_ticket
        @id_ticket = 1,
        @nuevo_estado = 2,
        @id_usuario = 1;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrorCode, ERROR_MESSAGE() AS ErrorMessage;
END CATCH


-- CASO 12: Reasignar ticket a empleado activo

UPDATE Empleado SET estado = 'Activo' WHERE id_empleado = 2;

EXEC sp_reasignar_ticket
    @id_ticket = 1,
    @nuevo_empleado = 2,
    @usuario_actual = 1;

SELECT * FROM Ticket WHERE id_ticket = 1;


-- CASO 13: Reasignar ticket a empleado inactivo

UPDATE Empleado SET estado = 'Inactivo' WHERE id_empleado = 2;

BEGIN TRY
    EXEC sp_reasignar_ticket
        @id_ticket = 1,
        @nuevo_empleado = 2,
        @usuario_actual = 2;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrorCode, ERROR_MESSAGE() AS ErrorMessage;
END CATCH


-- CASO 14: Cerrar ticket

EXEC sp_cambiar_estado_ticket
    @id_ticket = 1,
    @nuevo_estado = 5,
    @id_usuario = 2;

SELECT * FROM Ticket WHERE id_ticket = 1;


-- CASO 15: Intentar cambiar estado por otro usuario

BEGIN TRY
    EXEC sp_cambiar_estado_ticket
        @id_ticket = 1,
        @nuevo_estado = 4,
        @id_usuario = 1;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrorCode, ERROR_MESSAGE() AS ErrorMessage;
END CATCH


-- CASO 16: Modificar nombre/apellido de cliente activo

BEGIN TRY
    UPDATE Persona
    SET nombre = 'NuevoNombre'
    WHERE tipo_documento = 'DNI' AND nro_documento = '12345678';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrorCode, ERROR_MESSAGE() AS ErrorMessage;
END CATCH


-- CASO 17: Modificar nombre/apellido de prospecto

UPDATE Persona
SET nombre = 'LauraActualizado'
WHERE tipo_documento = 'DNI' AND nro_documento = '33445566';

SELECT * FROM Persona WHERE tipo_documento = 'DNI' AND nro_documento = '33445566';


-- CASO 18: Modificar fecha nacimiento de cliente activo

BEGIN TRY
    UPDATE Persona
    SET fecha_nacimiento = '1980-01-01'
    WHERE tipo_documento = 'DNI' AND nro_documento = '12345678';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrorCode, ERROR_MESSAGE() AS ErrorMessage;
END CATCH


-- CASO 19: Crear prospecto con email inválido (debe dar error ahora que lo agregaste)

BEGIN TRY
    EXEC sp_alta_prospecto
        @tipo_documento = 'DNI',
        @nro_documento = '66778899',
        @nombre = 'Lucia',
        @apellido = 'Perez',
        @email = 'email_invalido',
        @fecha_nacimiento = '1990-05-05';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrorCode, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
