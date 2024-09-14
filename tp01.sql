--EJERCICIO 01
CREATE DATABASE "BaseTP01";
go
use "BaseTP01";

--EJERCICIO 02
CREATE SCHEMA ddbba AUTHORIZATION dbo;

--EJERCICIO 03
CREATE TABLE ddbba.registro(
	id int IDENTITY(1,1) PRIMARY KEY,--genera valores automaticamente(inicio, incremento)
	fecha_hora DATETIME DEFAULT GETDATE(),--genera el tiempo actual del sistema en el momento que se realiza la insercion
	texto varchar(50),
	modulo varchar(10)
);

SELECT * FROM ddbba.registro;

--EJERCICIO 04
CREATE OR ALTER PROCEDURE ddbba.insertarLog @modulo varchar(10), @texto varchar(50) 
AS
BEGIN
	--VERIFICO SI EL MODULO VIENE VACIO
	IF @modulo IS NULL
		SET @modulo = 'N/A';
	--INSERTO LOS DATOS EN LA TABLA DE REGISTROS
	INSERT INTO ddbba.registro(modulo, texto) VALUES (@modulo, @texto);
END

--EJERCICIO 05
CREATE TABLE ddbba.persona(
	id_persona int IDENTITY(1,1) PRIMARY KEY,
	dni varchar(10) NOT NULL,
	telefono varchar(15),
	localidad varchar(50),
	fechaNacimiento DATE,
	nombre varchar(50),
	apellido varchar(50)
)

CREATE TABLE ddbba.materia(
	id_materia int IDENTITY(1,1) PRIMARY KEY,
	nombre varchar(50)
)

CREATE TABLE ddbba.curso(
	id_curso int IDENTITY(1000,1) PRIMARY KEY,
	numeroComision varchar(4),
	id_materia int,
	CONSTRAINT fk_materia FOREIGN KEY (id_materia) REFERENCES ddbba.materia(id_materia)
)

CREATE TABLE ddbba.vehiculo(
	id_vehiculo int IDENTITY(1,1) PRIMARY KEY,
	id_persona int,
	patente char(7),
	CONSTRAINT fk_persona FOREIGN KEY (id_persona) REFERENCES ddbba.persona(id_persona),
	CONSTRAINT CK_patente CHECK(
		patente LIKE '[A-Z] [A-Z] [0-9] [0-9] [0-9] [A-Z] [A-Z]' --AUTO PAT NUEVA
		OR 
		patente LIKE '[A-Z] [0-9] [0-9] [0-9] [A-Z] [A-Z] [A-Z]' --MOTO PAT NUEVA
		OR 
		patente LIKE '[A-Z] [A-Z] [A-Z] [0-9] [0-9] [0-9]' --AUTO ~ MOTO PAT VIEJA
	)
)

CREATE TABLE ddbba.cursa(
	id_cursa int IDENTITY(1,1) PRIMARY KEY,
	id_persona int,
	id_curso int,
	es_docente bit,
	CONSTRAINT fk_persona FOREIGN KEY (id_persona) REFERENCES ddbba.persona(id_persona),
	CONSTRAINT fk_curso FOREIGN KEY (id_curso) REFERENCES ddbba.curso(id_curso)
)

--Ejercicio 07
/*
Cree un stored procedure para generar registros aleatorios en la tabla de alumnos.
Para ello genere una tabla de nombres que tenga valores de nombres y apellidos
que podrá combinar de forma aleatoria. Al generarse cada registro de alumno tome
al azar dos valores de nombre y uno de apellido. El resto de los valores (localidad,
fecha de nacimiento, DNI, etc.) genérelos en forma aleatoria también. El SP debe
admitir un parámetro para indicar la cantidad de registros a generar
*/

CREATE OR ALTER PROCEDURE ddbba.insertarAlumno 
    @cantidadRegistros INT
AS
BEGIN 
    DECLARE @counter INT = 0

    WHILE @counter < @cantidadRegistros
    BEGIN
        INSERT INTO ddbba.persona(dni, telefono, localidad, fechaNacimiento, nombre, apellido)
        VALUES (
            CASE 
                WHEN RAND() < 0.1 THEN '100000000' -- 10% de probabilidades de generar '100000000'
                ELSE CAST(RAND() * 1000000000 AS INT)
            END,
            CAST(RAND() * 1000000000 AS INT),
            CASE CAST(RAND() * (5 - 1) + 1 AS INT)
                WHEN 1 THEN 'CABA'
                WHEN 2 THEN 'La Plata'
                WHEN 3 THEN 'Mar del Plata'
                WHEN 4 THEN 'Rosario'
                WHEN 5 THEN 'Cordoba'
				ELSE 'Buenos Aires'
            END,
            CASE CAST(RAND() * (5 - 1) + 1 AS INT)
                WHEN 1 THEN '1999-01-01'
                WHEN 2 THEN '2000-01-01'
                WHEN 3 THEN '2001-01-01'
                WHEN 4 THEN '2002-01-01'
                WHEN 5 THEN '2003-01-01'
				ELSE '2004-01-01'
            END,
            CASE CAST(RAND() * (5 - 1) + 1 AS INT)
                WHEN 1 THEN 'Juan'
                WHEN 2 THEN 'Pedro'
                WHEN 3 THEN 'Luis'
                WHEN 4 THEN 'Jose'
                WHEN 5 THEN 'Lucia'
				ELSE 'Maria'
            END,
            CASE CAST(RAND() * (5 - 1) + 1 AS INT)
                WHEN 1 THEN 'Perez'
                WHEN 2 THEN 'Gomez'
                WHEN 3 THEN 'Rodriguez'
                WHEN 4 THEN 'Fernandez'
                WHEN 5 THEN 'Gonzalez'
				ELSE 'Pia' 
            END
        )

        SET @counter = @counter + 1
    END
END

/*8. Utilizando el SP creado en el punto anterior, genere 1000 registros de alumnos.*/
exec ddbba.insertarAlumno 20000

select top 100 * from ddbba.persona
delete from ddbba.persona;

/*9. Elimine los registros duplicados utilizando common table expressions.*/
WITH CTE AS (
    SELECT id_persona, dni, telefono, localidad, fechaNacimiento, nombre, apellido,
           ROW_NUMBER() OVER (PARTITION BY dni ORDER BY id_persona) AS rn
    FROM ddbba.persona
)
--SELECT * FROM CTE WHERE RN >1
DELETE FROM CTE WHERE rn > 1;

/*10**/

CREATE OR ALTER PROCEDURE ddbba.insertarComisiones 
AS
BEGIN
    DECLARE @materiaId INT;
    DECLARE @numeroComision INT;
    DECLARE @cantidadComisiones INT;
    
    -- Obtén la cantidad total de materias
    DECLARE @materiasCount INT = (SELECT COUNT(*) FROM ddbba.materia);

    -- Asegúrate de que haya al menos una materia
    IF @materiasCount = 0
    BEGIN
        PRINT 'No hay materias en la base de datos.';
        RETURN;
    END

    -- Itera sobre cada materia
    WHILE @materiasCount > 0
    BEGIN
        -- Selecciona una materia aleatoria
        SET @materiaId = (SELECT TOP 1 id_materia FROM ddbba.materia ORDER BY NEWID());

        -- Genera un número de comisiones aleatorio entre 1 y 5
        SET @cantidadComisiones = ABS(CHECKSUM(NEWID())) % 5 + 1;
        
        SET @numeroComision = 1;

        -- Inserta las comisiones para la materia seleccionada
        WHILE @numeroComision <= @cantidadComisiones
        BEGIN
            INSERT INTO ddbba.curso(numeroComision, id_materia)
            VALUES (FORMAT(@numeroComision, '0000'), @materiaId);

            SET @numeroComision = @numeroComision + 1;
        END

        -- Decrementa la cantidad de materias
        SET @materiasCount = @materiasCount - 1;
    END
END


exec ddbba.insertarComisiones
SELECT  * FROM ddbba.curso

--11
