USE [TP-BD2];
GO

-- 1) Vista de Clientes (oculta tipo y número de documento)
CREATE VIEW vw_Clientes_Seguro AS
SELECT
    C.id_cliente,
    P.nombre,
    P.apellido,
    P.email,
    P.estado AS estado_persona,
    P.cliente_o_prospecto
FROM Cliente C
JOIN Persona P ON C.tipo_documento = P.tipo_documento AND C.nro_documento = P.nro_documento;
GO

-- 2) Vista de Tickets Resumida (oculta login de empleado)
CREATE VIEW vw_Tickets_Resumen AS
SELECT
    T.id_ticket,
    CT.id_cliente,
    ET.descripcion AS estado_ticket,
    TT.descripcion AS tipo_ticket,
    T.fecha_hora_apertura,
    T.fecha_hora_resolucion,
    E.nombre AS empleado_nombre,
    E.apellido AS empleado_apellido
FROM Ticket T
JOIN Clientes_Tickets CT ON T.id_ticket = CT.id_ticket
JOIN Estado_Ticket ET ON T.id_estado = ET.id_estado
JOIN Tipo_Ticket TT ON T.id_tipo_ticket = TT.id_tipo_ticket
JOIN Empleado E ON T.id_empleado = E.id_empleado;
GO

-- 3) Vista para Cálculo de Cumplimiento de SLA
CREATE VIEW vw_SLA_Cumplimiento AS
SELECT
    T.id_ticket,
    CT.id_cliente,
    TT.descripcion AS tipo_ticket,
    ET.descripcion AS estado_actual,
    DATEDIFF(HOUR, T.fecha_hora_apertura, T.fecha_hora_resolucion) AS horas_transcurridas,
    S.tiempo_maximo AS horas_permitidas,
    CASE
        WHEN T.fecha_hora_resolucion IS NOT NULL
             AND DATEDIFF(HOUR, T.fecha_hora_apertura, T.fecha_hora_resolucion) <= S.tiempo_maximo
        THEN 'Cumple'
        ELSE 'No Cumple'
    END AS cumple_sla
FROM Ticket T
JOIN Clientes_Tickets CT ON T.id_ticket = CT.id_ticket
JOIN Tipo_Ticket TT ON T.id_tipo_ticket = TT.id_tipo_ticket
JOIN Estado_Ticket ET ON T.id_estado = ET.id_estado
JOIN SLA S ON S.id_estado = 4 AND S.id_tipo_ticket = T.id_tipo_ticket
WHERE T.fecha_hora_resolucion IS NOT NULL;
GO
