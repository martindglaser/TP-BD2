CREATE TABLE Tipo_Servicio (
	id_tipo_servicio int PRIMARY KEY,
	nombre_servicio VARCHAR(150)
);

CREATE TABLE Servicio (
	id_servicio int PRIMARY KEY,
	id_tipo_servicio int,
	telefono VARCHAR(150),
	calle VARCHAR(150),
	numero int,
	piso int,
	depto int,
	fecha_inicio DATE,
	estado VARCHAR(150),
	CONSTRAINT FK_Servicio_Tipo_Servicio FOREIGN KEY (id_tipo_servicio) REFERENCES Tipo_Servicio(id_tipo_servicio)
);


CREATE TABLE Persona (
	tipo_documento VARCHAR(150),
	nro_documento VARCHAR(150),
	fecha_nacimiento DATE,
	email VARCHAR(150),
	estado VARCHAR(150),
	nombre VARCHAR(150),
	apellido VARCHAR(150),
	cliente_o_prospecto VARCHAR(150),
	PRIMARY KEY(tipo_documento, nro_documento)
);


CREATE TABLE Cliente (
	tipo_documento VARCHAR(150),
	nro_documento VARCHAR(150),
	id_cliente int,
	PRIMARY KEY(id_cliente),
	CONSTRAINT FK_ClientePersona FOREIGN KEY (tipo_documento, nro_documento) REFERENCES Persona(tipo_documento, nro_documento)
);

CREATE TABLE Prospecto (
	tipo_documento VARCHAR(150),
	nro_documento VARCHAR(150),
	id_prospecto int,
	PRIMARY KEY(id_prospecto),
	CONSTRAINT FK_ProspectoPersona FOREIGN KEY (tipo_documento, nro_documento) REFERENCES Persona(tipo_documento, nro_documento)
);


CREATE TABLE Cientes_Servicios (
	id_cliente int,
	id_servicio int,
	PRIMARY KEY(id_cliente, id_servicio),
	CONSTRAINT FK_Clientes_Servicios_Cliente FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente),
	CONSTRAINT FK_Clientes_Servicios_Servicio FOREIGN KEY (id_servicio) REFERENCES Servicio(id_servicio)
);


CREATE TABLE Estado_Ticket (
    id_estado int PRIMARY KEY,
    descripcion VARCHAR(150)
);


CREATE TABLE Tipo_Ticket (
    id_tipo_ticket int PRIMARY KEY,
    descripcion VARCHAR(150)
);


CREATE TABLE Empleado (
    id_empleado INT PRIMARY KEY,
    nombre VARCHAR(150),
    apellido VARCHAR(150),
    login VARCHAR(150) UNIQUE,
    estado VARCHAR(150)
);


CREATE TABLE Ticket (
    id_ticket INT PRIMARY KEY,
    id_estado INT FOREIGN KEY REFERENCES Estado_Ticket(id_estado),
    id_tipo_ticket INT FOREIGN KEY REFERENCES Tipo_Ticket(id_tipo_ticket),
    id_empleado INT FOREIGN KEY REFERENCES Empleado(id_empleado),
    fecha_hora_apertura DATETIME DEFAULT GETDATE(),
    fecha_hora_resolucion DATETIME
);


CREATE TABLE Clientes_Tickets (
	id_cliente int,
	id_ticket int,
	PRIMARY KEY(id_cliente,id_ticket),
	CONSTRAINT FK_Clientes_Tickets_Cliente FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente),
	CONSTRAINT FK_Clientes_Tickets_Ticket FOREIGN KEY (id_ticket) REFERENCES Ticket(id_ticket),
);


CREATE TABLE SLA (
    id_estado int FOREIGN KEY REFERENCES Estado_Ticket(id_estado),
    id_tipo_ticket int FOREIGN KEY REFERENCES Tipo_Ticket(id_tipo_ticket),
    tiempo_maximo INT,
    PRIMARY KEY (id_estado, id_tipo_ticket),
);