-- 1. Tabla Padre
CREATE TABLE IF NOT EXISTS Usuarios (
    rut VARCHAR(12) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tipo VARCHAR(50) NOT NULL
);

-- 2. Credenciales
CREATE TABLE IF NOT EXISTS Usuarios_loggeo (
    rut VARCHAR(12) PRIMARY KEY,
    correo VARCHAR(100) UNIQUE NOT NULL,
    contrasena VARCHAR(255) NOT NULL,
    FOREIGN KEY (rut) REFERENCES Usuarios(rut) ON DELETE CASCADE
);

-- 3. Empresa
CREATE TABLE IF NOT EXISTS Empresa (
    rut VARCHAR(12) PRIMARY KEY,
    resena TEXT,
    FOREIGN KEY (rut) REFERENCES Usuarios(rut) ON DELETE CASCADE
);

-- 4. Estudiante (NUEVO: Se agregan latitud y longitud)
CREATE TABLE IF NOT EXISTS Estudiante (
    rut VARCHAR(12) PRIMARY KEY,
    a_paterno VARCHAR(50) NOT NULL,
    a_materno VARCHAR(50) NOT NULL,
    rol VARCHAR(20) NOT NULL,
    direccion VARCHAR(255),
    telefono VARCHAR(20),
    distancia NUMERIC,
    latitud NUMERIC(10, 7),
    longitud NUMERIC(10, 7),
    FOREIGN KEY (rut) REFERENCES Usuarios(rut) ON DELETE CASCADE
);

-- 4.1 Preferencias del Estudiante
CREATE TABLE IF NOT EXISTS Preferencias_Estudiante (
    rut_estudiante VARCHAR(12),
    preferencia VARCHAR(100),
    PRIMARY KEY (rut_estudiante, preferencia),
    FOREIGN KEY (rut_estudiante) REFERENCES Estudiante(rut) ON DELETE CASCADE
);

-- 5. Funcionarios
CREATE TABLE IF NOT EXISTS Funcionarios (
    rut VARCHAR(12) PRIMARY KEY,
    departamento VARCHAR(100),
    cargo VARCHAR(100),
    FOREIGN KEY (rut) REFERENCES Usuarios(rut) ON DELETE CASCADE
);

-- 6. Supervisor
CREATE TABLE IF NOT EXISTS Supervisor_Practica (
    rut VARCHAR(12) PRIMARY KEY,
    nom_empresa VARCHAR(100),
    FOREIGN KEY (rut) REFERENCES Usuarios(rut) ON DELETE CASCADE
);

-- 7. Práctica (NUEVO: Se integran modalidad, latitud y longitud directamente)
CREATE TABLE IF NOT EXISTS Practica (
    id SERIAL PRIMARY KEY,
    rut_empresa VARCHAR(12) NOT NULL, 
    ubicacion VARCHAR(255),
    cargo VARCHAR(100),
    cant_horas INTEGER,
    descripcion TEXT,
    rut_supervisor VARCHAR(12),
    remuneracion INTEGER,
    modalidad VARCHAR(50),
    latitud NUMERIC(10, 7),
    longitud NUMERIC(10, 7),
    FOREIGN KEY (rut_empresa) REFERENCES Empresa(rut) ON DELETE CASCADE,
    FOREIGN KEY (rut_supervisor) REFERENCES Supervisor_Practica(rut) ON DELETE SET NULL
);

-- Catálogo central de habilidades
CREATE TABLE IF NOT EXISTS Habilidades (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    categoria VARCHAR(100) NOT NULL
);

-- Seed inicial de habilidades
INSERT INTO Habilidades (nombre, categoria) VALUES
    ('JavaScript', 'Lenguajes de Programación'), ('Python', 'Lenguajes de Programación'),
    ('Java', 'Lenguajes de Programación'), ('C++', 'Lenguajes de Programación'),
    ('TypeScript', 'Lenguajes de Programación'), ('SQL', 'Lenguajes de Programación'),
    ('React', 'Frameworks y Librerías'), ('Node.js', 'Frameworks y Librerías'),
    ('Spring Boot', 'Frameworks y Librerías'), ('Django', 'Frameworks y Librerías'),
    ('Angular', 'Frameworks y Librerías'), ('PostgreSQL', 'Bases de Datos y Entornos'),
    ('MySQL', 'Bases de Datos y Entornos'), ('MongoDB', 'Bases de Datos y Entornos'),
    ('Linux', 'Bases de Datos y Entornos'), ('Git', 'Bases de Datos y Entornos'),
    ('Docker', 'Bases de Datos y Entornos'), ('Excel Avanzado', 'Dominio en Software'),
    ('Power BI', 'Dominio en Software'), ('Figma', 'Dominio en Software'),
    ('AutoCAD', 'Dominio en Software'), ('SAP', 'Dominio en Software'),
    ('Inglés Básico', 'Idiomas'), ('Inglés Técnico (Lectura)', 'Idiomas'),
    ('Inglés Intermedio', 'Idiomas'), ('Inglés Avanzado', 'Idiomas'),
    ('Trabajo en equipo', 'Competencias'), ('Proactividad', 'Competencias'),
    ('Liderazgo', 'Competencias'), ('Resolución de problemas', 'Competencias')
ON CONFLICT (nombre) DO NOTHING;

-- Habilidades requeridas por cada práctica
CREATE TABLE IF NOT EXISTS Habilidades_Practica (
    id_practica INTEGER,
    id_habilidad INTEGER,
    PRIMARY KEY (id_practica, id_habilidad),
    FOREIGN KEY (id_practica) REFERENCES Practica(id) ON DELETE CASCADE,
    FOREIGN KEY (id_habilidad) REFERENCES Habilidades(id) ON DELETE CASCADE
);

-- Habilidades del estudiante
CREATE TABLE IF NOT EXISTS Habilidades_Estudiante (
    rut_estudiante VARCHAR(12),
    id_habilidad INTEGER,
    PRIMARY KEY (rut_estudiante, id_habilidad),
    FOREIGN KEY (rut_estudiante) REFERENCES Estudiante(rut) ON DELETE CASCADE,
    FOREIGN KEY (id_habilidad) REFERENCES Habilidades(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS practica_en_proceso (
    rut VARCHAR(12),
    id_practica SERIAL,
    rut_supervisor VARCHAR(12),
    ruta_archivo VARCHAR(255),
    estado VARCHAR(20),
    PRIMARY KEY (rut, id_practica),
    FOREIGN KEY (rut) REFERENCES Usuarios(rut) ON DELETE CASCADE,
    FOREIGN KEY (id_practica) REFERENCES Practica(id) ON DELETE CASCADE,
    FOREIGN KEY (rut_supervisor) REFERENCES Supervisor_Practica(rut) 
);

-- Fecha límite de postulación por oferta (NULL = sin vencimiento)
ALTER TABLE practica ADD COLUMN IF NOT EXISTS fecha_cierre DATE;

ALTER TABLE practica_en_proceso
  ADD COLUMN IF NOT EXISTS fecha_postulacion   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT NOW();

CREATE TABLE IF NOT EXISTS historial_estados (
  id              SERIAL PRIMARY KEY,
  rut             VARCHAR(12) NOT NULL,
  id_practica     INTEGER     NOT NULL,
  estado_anterior VARCHAR(30),
  estado_nuevo    VARCHAR(30) NOT NULL,
  actor           VARCHAR(20) NOT NULL,       -- rut del usuario o 'sistema'
  motivo          TEXT,
  fecha           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  FOREIGN KEY (rut, id_practica) REFERENCES practica_en_proceso(rut, id_practica) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_pep_estado      ON practica_en_proceso (estado);
CREATE INDEX IF NOT EXISTS idx_practica_cierre ON practica (fecha_cierre);



-- ============================================================================
-- 2. INSERCIÓN DE USUARIOS BASE
-- ============================================================================
INSERT INTO usuarios (rut, nombre, tipo) VALUES
('76000001-0', 'TechSolutions AWS', 'Empresa'), ('76000002-9', 'Felicity Solar Tech', 'Empresa'),
('76000003-7', 'Innova Redes', 'Empresa'), ('76000004-5', 'CloudMasters', 'Empresa'),
('76000005-3', 'DevOps Chile', 'Empresa'), ('76000006-1', 'CiberSeguridad Sur', 'Empresa'),
('76000007-K', 'DataMining SA', 'Empresa'), ('76000008-8', 'Sistemas y Redes', 'Empresa'),
('76000009-6', 'IA SpA', 'Empresa'), ('76000010-K', 'Infra Segura', 'Empresa'),
('15000000-0', 'Coordinador de Prácticas', 'Encargado'),
('20000001-0', 'Andres Felipe Muñoz Araya', 'Estudiante'), ('20000002-9', 'Beatriz Elena Silva Perez', 'Estudiante'),
('20000003-7', 'Carlos Alberto Torres Rios', 'Estudiante'), ('20000004-5', 'Daniela Paz Ramirez Castro', 'Estudiante'),
('20000005-3', 'Esteban Andres Flores Vargas', 'Estudiante'), ('20000006-1', 'Fernanda Isabel Valdes Morales', 'Estudiante'),
('20000007-K', 'Gabriel Ignacio Castillo Soto', 'Estudiante'),('20000008-8', 'Hector Manuel Pizarro Gomez', 'Estudiante'),
('20000009-6', 'Ignacia Antonia Reyes Fuentes', 'Estudiante'), ('20000010-K', 'Javier Eduardo Medina Bravo', 'Estudiante'),
('20000011-8', 'Karla Andrea Castro Quiroz', 'Estudiante'), ('20000012-6', 'Luis Antonio Morales Herrera', 'Estudiante'),
('20000013-4', 'Maria Jose Herrera Jara', 'Estudiante'), ('20000014-2', 'Nicolas Matias Aguilar Diaz', 'Estudiante'),
('20000015-0', 'Oscar Rene Vega Tapia', 'Estudiante'), ('20000016-9', 'Paula Andrea Fuentes Navarro', 'Estudiante'),
('20000017-7', 'Quintin Arturo Cabrera Lagos', 'Estudiante'),('20000018-5', 'Rosa Maria Mendoza Zapata', 'Estudiante'),
('20000019-3', 'Sergio Andres Salazar Osorio', 'Estudiante'), ('20000020-7', 'Teresa Soledad Guzman Escobar', 'Estudiante'),
('20000021-5', 'Ulises Daniel Vargas Ibarra', 'Estudiante'), ('20000022-3', 'Victoria Paz Ortiz Urrutia', 'Estudiante'),
('20000023-1', 'William Alexander Rios Yañez', 'Estudiante'), ('20000024-K', 'Ximena Andrea Navarro Campos', 'Estudiante'),
('20000025-8', 'Yamil Enrique Moya Miranda', 'Estudiante'), ('20000026-6', 'Zoe Antonella Araya Alvarado', 'Estudiante'),
('20000027-4', 'Alejandro Tomas Pino Rojas', 'Estudiante'), ('20000028-2', 'Bastian Alonso Lagos Leiva', 'Estudiante'),
('20000029-0', 'Camila Ignacia Riquelme Godoy', 'Estudiante'),('20000030-4', 'Diego Sebastian Bravo Toro', 'Estudiante'),
('20000031-2', 'Emilio Javier Carrasco Peña', 'Estudiante'),('20000032-0', 'Fabiola Andrea Saavedra Diaz', 'Estudiante'),
('20000033-9', 'Gonzalo Andres Tapia Salinas', 'Estudiante'), ('20000034-7', 'Hugo Patricio Contreras Vera', 'Estudiante'),
('20000035-5', 'Isabel Margarita Godoy Cardenas', 'Estudiante'), ('20000036-3', 'Jorge Luis Orellana Muñoz', 'Estudiante'),
('20000037-1', 'Karen Daniela Cardenas Bustos', 'Estudiante'), ('20000038-K', 'Lucas Mateo Leiva Fuentes', 'Estudiante'),
('20000039-8', 'Matias Nicolas Soto Henriquez', 'Estudiante'), ('20000040-1', 'Natalia Belen Rojas Jimenez', 'Estudiante'),
('20000041-K', 'Omar Alonso Vidal Quintana', 'Estudiante'), ('20000042-8', 'Patricio Esteban Ruiz Nuñez', 'Estudiante'),
('20000043-6', 'Quimey Ayelen Mella Williams', 'Estudiante'), ('20000044-4', 'Roberto Carlos Peña Ximenez', 'Estudiante'),
('20000045-2', 'Sofia Catalina Carvajal Krauss', 'Estudiante'), ('20000046-0', 'Tomas Felipe Vergara Astudillo', 'Estudiante'),
('20000047-9', 'Ursula Macarena Pinto Pavez', 'Estudiante'), ('20000048-7', 'Vicente Gabriel Donoso Rivas', 'Estudiante')
ON CONFLICT (rut) DO NOTHING;

-- ============================================================================
-- 3. CREDENCIALES DE ACCESO
-- ============================================================================
INSERT INTO usuarios_loggeo (rut, correo, contrasena) VALUES
('76000001-0', 'contacto@techsolutions.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('76000002-9', 'rrhh@felicity.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('76000003-7', 'admin@innovaredes.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('76000004-5', 'jobs@cloudmasters.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('76000005-3', 'talento@devops.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('76000006-1', 'reclutamiento@cibersur.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('76000007-K', 'contacto@datamining.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('76000008-8', 'postulaciones@sistemasredes.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('76000009-6', 'empleos@iaspa.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('76000010-K', 'rrhh@infrasegura.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('15000000-0', 'coordinador.practicas@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000001-0', 'amunoza@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000002-9', 'bsilvap@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000003-7', 'ctorresr@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000004-5', 'dramirezc@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000005-3', 'efloresv@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000006-1', 'fvaldesm@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000007-K', 'gcastillos@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000008-8', 'hpizarrog@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000009-6', 'ireyesf@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000010-K', 'jmedinab@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000011-8', 'kcastroq@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000012-6', 'lmoralesh@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000013-4', 'mherreraj@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000014-2', 'naguilard@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000015-0', 'ovegat@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000016-9', 'pfuentesn@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000017-7', 'qcabreral@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000018-5', 'rmendozaz@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000019-3', 'ssalazaro@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000020-7', 'tguzmane@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000021-5', 'uvargasi@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000022-3', 'vortizu@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000023-1', 'wriosy@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000024-K', 'xnavarroc@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000025-8', 'ymoyam@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000026-6', 'zarayaa@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000027-4', 'apinor@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000028-2', 'blagosl@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000029-0', 'criquelmeg@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000030-4', 'dbravot@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000031-2', 'ecarrascop@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000032-0', 'fsaavedrad@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000033-9', 'gtapias@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000034-7', 'hcontrerasv@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000035-5', 'igodoyc@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000036-3', 'jorellanam@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000037-1', 'kcardenasb@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000038-K', 'lleivaf@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000039-8', 'msotoh@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000040-1', 'nrojasj@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000041-K', 'ovidalq@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000042-8', 'pruizn@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000043-6', 'qmellaw@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000044-4', 'rpenax@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000045-2', 'scarvajalk@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000046-0', 'tvergaraa@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'),
('20000047-9', 'upintop@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi'), ('20000048-7', 'vdonosor@usm.cl', '$2b$10$IongQow0E3DiZsfXf1t55./i3f/18XA5.o7ME1kEI0d2NyLCZ01hi')
ON CONFLICT (rut) DO NOTHING;

-- ============================================================================
-- 4. RELACIONES MAESTRAS DE IDENTIDADES Y DIRECCIONES ALEATORIAS DE ESTUDIANTES
-- ============================================================================
INSERT INTO empresa (rut, resena) VALUES
('76000001-0', 'Expertos en servicios de AWS y monitoreo de enlaces web.'),
('76000002-9', 'Instalación y monitoreo de sistemas de energía solar.'),
('76000003-7', 'Configuración de switches y routers a nivel corporativo.'),
('76000004-5', 'Desarrollo e implementación de servidores en la nube.'),
('76000005-3', 'Automatización de despliegues y operaciones de IT.'),
('76000006-1', 'Auditoría y pentesting de redes corporativas.'),
('76000007-K', 'Análisis de datos masivos y optimización de bases de datos.'),
('76000008-8', 'Soporte y arquitectura de redes físicas.'),
('76000009-6', 'Modelos de machine learning aplicados a operaciones.'),
('76000010-K', 'Especialistas en disponibilidad de infraestructura crítica.')
ON CONFLICT (rut) DO NOTHING;

INSERT INTO supervisor_practica (rut, nom_empresa) VALUES
('15000000-0', 'Universidad Técnica Federico Santa María')
ON CONFLICT (rut) DO NOTHING;

INSERT INTO estudiante (rut, a_paterno, a_materno, rol, direccion, telefono, distancia)
SELECT 
    rut, SPLIT_PART(nombre, ' ', 3), SPLIT_PART(nombre, ' ', 4),
    '202373' || LPAD(CAST(ROW_NUMBER() OVER() AS TEXT), 3, '0') || '-K',
    (ARRAY['Avenida Los Carrera', 'Calle Condell', 'Avenida España', 'Calle Álvarez', 'Avenida Libertad', 'Calle San Martín'])[floor(random() * 6) + 1] || ' ' || floor(random() * 2000 + 1) || ', ' || (ARRAY['Valparaíso', 'Viña del Mar', 'Quilpué', 'Villa Alemana', 'Santiago', 'Concón'])[floor(random() * 6) + 1],
    '+569' || LPAD(CAST(FLOOR(RANDOM() * 99999999) AS TEXT), 8, '0'),
    ROUND(CAST(RANDOM() * 15 AS NUMERIC), 1)
FROM usuarios WHERE tipo = 'Estudiante'
ON CONFLICT (rut) DO NOTHING;


-- ACTUALIZACIÓN DEL RESTO DE ESTUDIANTES A COORDENADAS POR DEFECTO PARA NO FALLAR
UPDATE estudiante SET latitud = -33.4489, longitud = -70.6693 WHERE latitud IS NULL;


-- ============================================================================
-- 5. OFERTAS DE PRÁCTICAS BASE
-- ============================================================================
INSERT INTO practica (id, rut_empresa, ubicacion, cargo, cant_horas, descripcion, rut_supervisor, remuneracion, modalidad) VALUES
(101, '76000001-0', 'Remoto', 'Practicante AWS y Redes', 320, 'Desarrollo de aplicativo para monitorear cortes en servidores AWS.', '15000000-0', 250000, 'Remoto'),
(102, '76000001-0', 'Valparaíso', 'Backend Developer', 160, 'Mantenimiento de bases de datos PostgreSQL.', '15000000-0', 200000, 'Híbrido'),
(3, '76000002-9', 'Quilpué', 'Soporte IoT', 320, 'Lectura de datos desde inversores solares y despliegue local.', '15000000-0', 150000, 'Presencial'),
(4, '76000002-9', 'Viña del Mar', 'Analista de Sistemas', 160, 'Documentación de diagramas UML para sistemas energéticos.', '15000000-0', 220000, 'Híbrido'),
(5, '76000003-7', 'Valparaíso', 'Ingeniero Junior en Redes', 320, 'Configuración de routers Huawei y switches capa 3.', '15000000-0', 250000, 'Presencial'),
(6, '76000003-7', 'Remoto', 'Analista de Tráfico', 160, 'Revisión de logs y acceso SSH en equipos de borde.', '15000000-0', 180000, 'Remoto'),
(7, '76000004-5', 'Santiago', 'Cloud Architect Intern', 320, 'Diseño de subinterfaces y arquitecturas cloud.', '15000000-0', 300000, 'Híbrido'),
(8, '76000004-5', 'Remoto', 'Soporte Técnico Nivel 1', 160, 'Atención de tickets y configuración básica de Linux.', '15000000-0', 150000, 'Remoto'),
(9, '76000005-3', 'Valparaíso', 'DevOps Junior', 320, 'Automatización de pipelines usando GitLab CI/CD.', '15000000-0', 250000, 'Híbrido'),
(10, '76000005-3', 'Santiago', 'Desarrollador C++', 160, 'Optimización de procesos internos.', '15000000-0', 280000, 'Remoto'),
(11, '76000006-1', 'Viña del Mar', 'Practicante Ciberseguridad', 320, 'Análisis de vulnerabilidades en aplicaciones web.', '15000000-0', 200000, 'Presencial'),
(12, '76000006-1', 'Remoto', 'Auditor de Código', 160, 'Revisión de seguridad en repositorios de software.', '15000000-0', 220000, 'Remoto'),
(13, '76000007-K', 'Santiago', 'Data Engineer Intern', 320, 'Extracción y limpieza de datos en PostgreSQL.', '15000000-0', 350000, 'Híbrido'),
(14, '76000007-K', 'Santiago', 'Analista BI', 160, 'Creación de dashboards interactivos.', '15000000-0', 250000, 'Híbrido'),
(15, '76000008-8', 'Valparaíso', 'Técnico de Terreno', 320, 'Instalación de cableado estructurado.', '15000000-0', 180000, 'Presencial'),
(16, '76000008-8', 'Curauma', 'Administrador de Redes', 160, 'Monitoreo de disponibilidad de infraestructura.', '15000000-0', 200000, 'Híbrido'),
(17, '76000009-6', 'Remoto', 'Machine Learning Intern', 320, 'Implementación de modelos AIOps con Python.', '15000000-0', 350000, 'Remoto'),
(18, '76000009-6', 'Remoto', 'Python Developer', 160, 'Desarrollo de scripts de automatización.', '15000000-0', 250000, 'Remoto'),
(19, '76000010-K', 'Santiago', 'Site Reliability Engineer', 320, 'Gestión de infraestructura en entornos Linux (Fedora/Ubuntu).', '15000000-0', 300000, 'Híbrido'),
(20, '76000010-K', 'Valparaíso', 'Soporte SO', 160, 'Resolución de incidencias en sistemas dual-boot.', '15000000-0', 150000, 'Presencial'),
(21, '76000001-0', 'Santiago', 'Fullstack Junior', 320, 'Desarrollo en Javascript, HTML y conexión con DB.', '15000000-0', 250000, 'Híbrido'),
(22, '76000002-9', 'Remoto', 'Desarrollador Java', 160, 'Mantenimiento de sistemas legacy.', '15000000-0', 220000, 'Remoto'),
(23, '76000003-7', 'Viña del Mar', 'Practicante Telecomunicaciones', 320, 'Pruebas de latencia en enlaces de radio.', '15000000-0', 180000, 'Presencial'),
(24, '76000004-5', 'Remoto', 'Arquitecto Cloud Junior', 160, 'Migración de servicios locales a la nube.', '15000000-0', 280000, 'Remoto'),
(25, '76000005-3', 'Valparaíso', 'QA Tester', 320, 'Creación de historias de usuario y pruebas unitarias.', '15000000-0', 200000, 'Híbrido'),
(26, '76000006-1', 'Santiago', 'Security Analyst', 160, 'Monitoreo de tráfico anómalo en la red.', '15000000-0', 250000, 'Presencial'),
(27, '76000007-K', 'Remoto', 'Database Administrator Intern', 320, 'Optimización de consultas lentas y respaldos.', '15000000-0', 300000, 'Remoto'),
(28, '76000008-8', 'Valparaíso', 'Especialista en Fibra', 160, 'Certificación de puntos de red corporativos.', '15000000-0', 180000, 'Presencial'),
(29, '76000009-6', 'Remoto', 'Desarrollador AIOps', 320, 'Entrenamiento de algoritmos predictivos de caídas.', '15000000-0', 400000, 'Remoto'),
(30, '76000010-K', 'Santiago', 'Sysadmin Junior', 160, 'Administración de servidores físicos y virtuales.', '15000000-0', 250000, 'Híbrido')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 6. ASIGNACIÓN MATEMÁTICA DE LAS COORDENADAS A LAS OFERTAS DE PRÁCTICA
-- ============================================================================
DO $$
DECLARE
    p_record RECORD;
    contador INT := 1;
    idx INT;
    
    valp_dirs TEXT[] := ARRAY['Av. España 1680, Valparaíso', 'Av. Errázuriz 1020, Valparaíso', 'Condell 1200, Valparaíso', 'Prat 700, Valparaíso', 'Av. Pedro Montt 2000, Valparaíso', 'Av. Brasil 2950, Valparaíso', 'Blanco 1199, Valparaíso', 'Esmeralda 1051, Valparaíso', 'Victoria 2800, Valparaíso', 'Independencia 2000, Valparaíso'];
    valp_lats NUMERIC[] := ARRAY[-33.0350, -33.0441, -33.0425, -33.0392, -33.0475, -33.0450, -33.0410, -33.0395, -33.0485, -33.0465];
    valp_lons NUMERIC[] := ARRAY[-71.5950, -71.6163, -71.6231, -71.6264, -71.6065, -71.6100, -71.6240, -71.6255, -71.6030, -71.6080];
    
    stgo_dirs TEXT[] := ARRAY['Av. Vicuña Mackenna 3939, San Joaquín', 'Carlos Valdovinos 200, San Joaquín', 'Av. Pedro de Valdivia 100, Providencia', 'Av. Libertador Bernardo O''Higgins 1058, Santiago', 'Huérfanos 1200, Santiago', 'Av. Santa Rosa 1500, San Miguel'];
    stgo_lats NUMERIC[] := ARRAY[-33.4900, -33.4833, -33.4285, -33.4442, -33.4398, -33.4905];
    stgo_lons NUMERIC[] := ARRAY[-70.6186, -70.6200, -70.6105, -70.6506, -70.6534, -70.6415];
BEGIN
    FOR p_record IN SELECT id FROM practica WHERE modalidad != 'Remoto' ORDER BY id LOOP
        IF contador <= 10 THEN
            idx := ((contador - 1) % 10) + 1;
            UPDATE practica SET ubicacion = valp_dirs[idx], latitud = valp_lats[idx], longitud = valp_lons[idx] WHERE id = p_record.id;
        ELSE
            idx := ((contador - 11) % array_length(stgo_dirs, 1)) + 1;
            UPDATE practica SET ubicacion = stgo_dirs[idx], latitud = stgo_lats[idx], longitud = stgo_lons[idx] WHERE id = p_record.id;
        END IF;
        contador := contador + 1;
    END LOOP;
END $$;

-- ============================================================================
-- 7. ASIGNACIÓN REQUERIDA DE HABILIDADES EN PRÁCTICAS Y ALEATORIAS
-- ============================================================================
INSERT INTO habilidades_practica (id_practica, id_habilidad) VALUES
(101, 2), (101, 15), (101, 17), (102, 3), (102, 12) 
ON CONFLICT (id_practica, id_habilidad) DO NOTHING;

DO $$
DECLARE
    st_record RECORD; pr_record RECORD;
    sk_pool INT[] := ARRAY[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30];
    skills_count INT := array_length(sk_pool, 1);
    num_to_assign INT; random_skill INT; i INT;
BEGIN
    FOR st_record IN SELECT rut FROM estudiante LOOP
        num_to_assign := floor(random() * 3) + 1;
        FOR i IN 1..num_to_assign LOOP
            random_skill := sk_pool[floor(random() * skills_count) + 1];
            BEGIN
                INSERT INTO habilidades_estudiante (rut_estudiante, id_habilidad) VALUES (st_record.rut, random_skill) ON CONFLICT DO NOTHING;
            EXCEPTION WHEN OTHERS THEN NULL; END;
        END LOOP;
    END LOOP;

    FOR pr_record IN SELECT id FROM practica WHERE id NOT IN (101, 102) LOOP
        num_to_assign := floor(random() * 3) + 2;
        FOR i IN 1..num_to_assign LOOP
            random_skill := sk_pool[floor(random() * skills_count) + 1];
            BEGIN
                INSERT INTO habilidades_practica (id_practica, id_habilidad) VALUES (pr_record.id, random_skill) ON CONFLICT DO NOTHING;
            EXCEPTION WHEN OTHERS THEN NULL; END;
        END LOOP;
    END LOOP;
END $$;

-- ============================================================================
-- 8. REINICIO DE LA SECUENCIA DE IDs PARA EVITAR EL ERROR 'DUPLICATE KEY'
-- ============================================================================
SELECT setval(pg_get_serial_sequence('practica', 'id'), COALESCE(max(id), 1)) FROM practica;

-- Normativa universitaria aplicable a las prácticas.
CREATE TABLE IF NOT EXISTS Normativa_Practica (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    horas_minimas INTEGER NOT NULL
        CHECK (horas_minimas > 0),
    plazo_entrega_dias INTEGER NOT NULL
        CHECK (plazo_entrega_dias > 0),
    requisitos_academicos TEXT NOT NULL,
    fecha_vigencia DATE NOT NULL DEFAULT CURRENT_DATE,
    activa BOOLEAN NOT NULL DEFAULT TRUE
);

-- Cada oferta puede especificar requisitos y fechas propios.
ALTER TABLE Practica
    ADD COLUMN IF NOT EXISTS requisitos_academicos TEXT,
    ADD COLUMN IF NOT EXISTS fecha_limite_postulacion DATE,
    ADD COLUMN IF NOT EXISTS fecha_limite_entrega DATE;