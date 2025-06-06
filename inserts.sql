USE [TP-BD2];
GO

INSERT INTO Tipo_Servicio (id_tipo_servicio, nombre_servicio) VALUES
(1, 'Telefonía Fija'),
(2, 'Internet'),
(3, 'VOIP');


INSERT INTO Servicio (id_servicio, id_tipo_servicio, telefono, calle, numero, piso, depto, fecha_inicio, estado) VALUES
(1, 1, '1144456677', 'Av. Siempre Viva', 742, 1, 2, '2023-01-10', 'Activo'),
(2, 2, NULL, 'Calle Falsa', 123, 3, 4, '2023-02-15', 'Activo'),
(3, 3, '1133356677', 'Av. Rivadavia', 9500, 5, 1, '2023-03-01', 'Inactivo');


INSERT INTO Persona (tipo_documento, nro_documento, fecha_nacimiento, email, estado, nombre, apellido, cliente_o_prospecto) VALUES
('DNI', '12345678', '1985-06-01', 'juan.perez@gmail.com', 'Activo', 'Juan', 'Perez', 'Cliente'),
('DNI', '87654321', '1990-09-15', 'maria.garcia@gmail.com', 'Inactivo', 'Maria', 'Garcia', 'Cliente'),
('DNI', '11223344', '2000-12-01', NULL, 'Prospecto', 'Pedro', 'Sanchez', 'Prospecto');


INSERT INTO Cliente (tipo_documento, nro_documento, id_cliente) VALUES
('DNI', '12345678', 1),
('DNI', '87654321', 2);


INSERT INTO Prospecto (tipo_documento, nro_documento, id_prospecto) VALUES
('DNI', '11223344', 1);


INSERT INTO Cientes_Servicios (id_cliente, id_servicio) VALUES
(1, 1),
(1, 2),
(2, 3);


INSERT INTO Estado_Ticket (id_estado, descripcion) VALUES
(1, 'Abierto'),
(2, 'En Progreso'),
(3, 'Pendiente Cliente'),
(4, 'Resuelto'),
(5, 'Cerrado');



INSERT INTO Tipo_Ticket (id_tipo_ticket, descripcion) VALUES
(1, 'Reimpresión de Factura'),
(2, 'Servicio Degradado'),
(3, 'Cambio de Velocidad'),
(4, 'Mudanza de servicio');


INSERT INTO Empleado (id_empleado, nombre, apellido, login, estado) VALUES
(1, 'Carlos', 'Ramirez', 'cramirez', 'Activo'),
(2, 'Ana', 'Lopez', 'alopez', 'Inactivo');



INSERT INTO Ticket (id_ticket, id_estado, id_tipo_ticket, id_empleado, fecha_hora_apertura, fecha_hora_resolucion) VALUES
(1, 1, 2, 1, '2025-06-01 10:00:00', NULL), -- abierto
(2, 4, 3, 1, '2025-05-01 08:30:00', '2025-05-02 10:00:00'); -- resuelto


INSERT INTO Clientes_Tickets (id_cliente, id_ticket) VALUES
(1, 1),
(2, 2);


INSERT INTO SLA (id_estado, id_tipo_ticket, tiempo_maximo) VALUES
(4, 1, 48), -- 48 horas para reimpresión
(4, 2, 24), -- 24 horas para servicio degradado
(4, 3, 36), -- 36 horas para cambio de velocidad
(4, 4, 72); -- 72 horas para mudanza