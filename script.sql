CREATE TABLE Tipo_Servicio (
	id_tipo_servicio int PRIMARY KEY,
	nombre_servicio VARCHAR
);

CREATE TABLE Servicio (
	id_servicio int PRIMARY KEY,
	id_tipo_servicio int,
	telefono VARCHAR,
	calle VARCHAR,
	numero int,
	piso int,
	depto int,
	fecha_inicio DATE,
	estado VARCHAR,
	CONSTRAINT FK_Servicio_Tipo_Servicio FOREIGN KEY (id_tipo_servicio) REFERENCES Tipo_Servicio(id_tipo_servicio)
);


CREATE TABLE Persona (
	tipo_documento VARCHAR,
	nro_documento VARCHAR,
	fecha_nacimiento DATE,
	email VARCHAR,
	estado VARCHAR,
	nombre VARCHAR,
	apellido VARCHAR,
	cliente_o_prospecto VARCHAR,
	PRIMARY KEY(tipo_documento, nro_documento)
);


CREATE TABLE Cliente (
	tipo_documento VARCHAR,
	nro_documento VARCHAR,
	id_cliente int,
	PRIMARY KEY(id_cliente),
	CONSTRAINT FK_ClientePersona FOREIGN KEY (tipo_documento, nro_documento) REFERENCES Persona(tipo_documento, nro_documento)
);

CREATE TABLE Prospecto (
	tipo_documento VARCHAR,
	nro_documento VARCHAR,
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


CREATE TABLE Clientes_Tickets (
	id_cliente int,
	id_ticket int,
	PRIMARY KEY(id_cliente,id_ticket),
	CONSTRAINT FK_Clientes_Tickets_Cliente FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente),
	CONSTRAINT FK_Clientes_Tickets_Ticket FOREIGN KEY (id_ticket) REFERENCES Ticket(id_ticket),
);