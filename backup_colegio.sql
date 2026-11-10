--
-- PostgreSQL database dump
--

\restrict Rkaa5Ij8VKQmgWER72MEgQmZ2WAJhOYoiLGgEfvELTPupGqbquuqBfeBr0IH937

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

-- Started on 2026-10-27 12:05:56

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 6 (class 2615 OID 16385)
-- Name: colegio_san_agustin; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA colegio_san_agustin;


ALTER SCHEMA colegio_san_agustin OWNER TO postgres;

--
-- TOC entry 237 (class 1255 OID 16514)
-- Name: fn_calcular_promedio(); Type: FUNCTION; Schema: colegio_san_agustin; Owner: postgres
--

CREATE FUNCTION colegio_san_agustin.fn_calcular_promedio() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_promedio NUMERIC(3,2);
BEGIN
    SELECT COALESCE(SUM(nota_obtenida * (porcentaje_peso / 100.0)), 0) INTO v_promedio
    FROM CALIFICACION WHERE id_matricula = NEW.id_matricula;

    UPDATE MATRICULA SET promedio_final = v_promedio WHERE id_matricula = NEW.id_matricula;
    RETURN NEW;
END;
$$;


ALTER FUNCTION colegio_san_agustin.fn_calcular_promedio() OWNER TO postgres;

--
-- TOC entry 236 (class 1255 OID 16512)
-- Name: fn_restaurar_cupo(); Type: FUNCTION; Schema: colegio_san_agustin; Owner: postgres
--

CREATE FUNCTION colegio_san_agustin.fn_restaurar_cupo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF OLD.estado = 'Inscrita' AND NEW.estado = 'Anulada' THEN
        UPDATE CURSO_GRUPO SET cupo_disponible = cupo_disponible + 1 WHERE id_curso = NEW.id_curso;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION colegio_san_agustin.fn_restaurar_cupo() OWNER TO postgres;

--
-- TOC entry 235 (class 1255 OID 16510)
-- Name: fn_validar_descontar_cupo(); Type: FUNCTION; Schema: colegio_san_agustin; Owner: postgres
--

CREATE FUNCTION colegio_san_agustin.fn_validar_descontar_cupo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_cupo_disponible INT;
    v_estado_estudiante VARCHAR;
BEGIN
    SELECT estado_academico INTO v_estado_estudiante FROM ESTUDIANTE WHERE id_estudiante = NEW.id_estudiante;
    IF v_estado_estudiante != 'Activo' THEN
        RAISE EXCEPTION 'El estudiante no está Activo [Estado Actual: %]', v_estado_estudiante;
    END IF;

    SELECT cupo_disponible INTO v_cupo_disponible FROM CURSO_GRUPO WHERE id_curso = NEW.id_curso;
    IF v_cupo_disponible <= 0 THEN
        RAISE EXCEPTION 'No hay cupos disponibles en el curso %.', NEW.id_curso;
    END IF;

    UPDATE CURSO_GRUPO SET cupo_disponible = cupo_disponible - 1 WHERE id_curso = NEW.id_curso;
    RETURN NEW;
END;
$$;


ALTER FUNCTION colegio_san_agustin.fn_validar_descontar_cupo() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 225 (class 1259 OID 16421)
-- Name: asignatura; Type: TABLE; Schema: colegio_san_agustin; Owner: postgres
--

CREATE TABLE colegio_san_agustin.asignatura (
    id_asignatura integer NOT NULL,
    codigo_materia character varying(20) NOT NULL,
    nombre character varying(100) NOT NULL,
    grado character varying(5) NOT NULL,
    intensidad_horaria integer,
    descripcion text,
    CONSTRAINT asignatura_grado_check CHECK (((grado)::text = ANY ((ARRAY['6°'::character varying, '7°'::character varying, '8°'::character varying, '9°'::character varying, '10°'::character varying, '11°'::character varying])::text[]))),
    CONSTRAINT asignatura_intensidad_horaria_check CHECK ((intensidad_horaria > 0))
);


ALTER TABLE colegio_san_agustin.asignatura OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16420)
-- Name: asignatura_id_asignatura_seq; Type: SEQUENCE; Schema: colegio_san_agustin; Owner: postgres
--

CREATE SEQUENCE colegio_san_agustin.asignatura_id_asignatura_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE colegio_san_agustin.asignatura_id_asignatura_seq OWNER TO postgres;

--
-- TOC entry 5111 (class 0 OID 0)
-- Dependencies: 224
-- Name: asignatura_id_asignatura_seq; Type: SEQUENCE OWNED BY; Schema: colegio_san_agustin; Owner: postgres
--

ALTER SEQUENCE colegio_san_agustin.asignatura_id_asignatura_seq OWNED BY colegio_san_agustin.asignatura.id_asignatura;


--
-- TOC entry 231 (class 1259 OID 16489)
-- Name: calificacion; Type: TABLE; Schema: colegio_san_agustin; Owner: postgres
--

CREATE TABLE colegio_san_agustin.calificacion (
    id_calificacion integer NOT NULL,
    id_matricula integer NOT NULL,
    periodo_corte integer NOT NULL,
    porcentaje_peso numeric(5,2) NOT NULL,
    nota_obtenida numeric(3,2) NOT NULL,
    observaciones text,
    CONSTRAINT calificacion_nota_obtenida_check CHECK (((nota_obtenida >= 0.00) AND (nota_obtenida <= 5.00))),
    CONSTRAINT calificacion_periodo_corte_check CHECK ((periodo_corte = ANY (ARRAY[1, 2, 3, 4]))),
    CONSTRAINT calificacion_porcentaje_peso_check CHECK (((porcentaje_peso >= (1)::numeric) AND (porcentaje_peso <= (100)::numeric)))
);


ALTER TABLE colegio_san_agustin.calificacion OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 16488)
-- Name: calificacion_id_calificacion_seq; Type: SEQUENCE; Schema: colegio_san_agustin; Owner: postgres
--

CREATE SEQUENCE colegio_san_agustin.calificacion_id_calificacion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE colegio_san_agustin.calificacion_id_calificacion_seq OWNER TO postgres;

--
-- TOC entry 5112 (class 0 OID 0)
-- Dependencies: 230
-- Name: calificacion_id_calificacion_seq; Type: SEQUENCE OWNED BY; Schema: colegio_san_agustin; Owner: postgres
--

ALTER SEQUENCE colegio_san_agustin.calificacion_id_calificacion_seq OWNED BY colegio_san_agustin.calificacion.id_calificacion;


--
-- TOC entry 227 (class 1259 OID 16438)
-- Name: curso_grupo; Type: TABLE; Schema: colegio_san_agustin; Owner: postgres
--

CREATE TABLE colegio_san_agustin.curso_grupo (
    id_curso integer NOT NULL,
    id_asignatura integer NOT NULL,
    id_docente integer NOT NULL,
    periodo_lectivo character varying(20) NOT NULL,
    grupo character varying(2) NOT NULL,
    cupo_maximo integer NOT NULL,
    cupo_disponible integer NOT NULL,
    aula_asignada character varying(20),
    CONSTRAINT curso_grupo_cupo_disponible_check CHECK ((cupo_disponible >= 0)),
    CONSTRAINT curso_grupo_cupo_maximo_check CHECK ((cupo_maximo > 0)),
    CONSTRAINT curso_grupo_grupo_check CHECK (((grupo)::text = ANY ((ARRAY['A'::character varying, 'B'::character varying, 'C'::character varying])::text[])))
);


ALTER TABLE colegio_san_agustin.curso_grupo OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16437)
-- Name: curso_grupo_id_curso_seq; Type: SEQUENCE; Schema: colegio_san_agustin; Owner: postgres
--

CREATE SEQUENCE colegio_san_agustin.curso_grupo_id_curso_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE colegio_san_agustin.curso_grupo_id_curso_seq OWNER TO postgres;

--
-- TOC entry 5113 (class 0 OID 0)
-- Dependencies: 226
-- Name: curso_grupo_id_curso_seq; Type: SEQUENCE OWNED BY; Schema: colegio_san_agustin; Owner: postgres
--

ALTER SEQUENCE colegio_san_agustin.curso_grupo_id_curso_seq OWNED BY colegio_san_agustin.curso_grupo.id_curso;


--
-- TOC entry 221 (class 1259 OID 16387)
-- Name: docente; Type: TABLE; Schema: colegio_san_agustin; Owner: postgres
--

CREATE TABLE colegio_san_agustin.docente (
    id_docente integer NOT NULL,
    documento_identidad character varying(20) NOT NULL,
    nombres character varying(100) NOT NULL,
    apellidos character varying(100) NOT NULL,
    especialidad character varying(50) NOT NULL,
    telefono character varying(15),
    email_institucional character varying(100) NOT NULL,
    activo boolean DEFAULT true
);


ALTER TABLE colegio_san_agustin.docente OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16386)
-- Name: docente_id_docente_seq; Type: SEQUENCE; Schema: colegio_san_agustin; Owner: postgres
--

CREATE SEQUENCE colegio_san_agustin.docente_id_docente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE colegio_san_agustin.docente_id_docente_seq OWNER TO postgres;

--
-- TOC entry 5114 (class 0 OID 0)
-- Dependencies: 220
-- Name: docente_id_docente_seq; Type: SEQUENCE OWNED BY; Schema: colegio_san_agustin; Owner: postgres
--

ALTER SEQUENCE colegio_san_agustin.docente_id_docente_seq OWNED BY colegio_san_agustin.docente.id_docente;


--
-- TOC entry 223 (class 1259 OID 16405)
-- Name: estudiante; Type: TABLE; Schema: colegio_san_agustin; Owner: postgres
--

CREATE TABLE colegio_san_agustin.estudiante (
    id_estudiante integer NOT NULL,
    documento_identidad character varying(20) NOT NULL,
    nombres character varying(100) NOT NULL,
    apellidos character varying(100) NOT NULL,
    fecha_nacimiento date NOT NULL,
    email_acudiente character varying(100),
    telefono_acudiente character varying(15),
    estado_academico character varying(20) NOT NULL,
    CONSTRAINT estudiante_estado_academico_check CHECK (((estado_academico)::text = ANY ((ARRAY['Activo'::character varying, 'Retirado'::character varying, 'Graduado'::character varying])::text[])))
);


ALTER TABLE colegio_san_agustin.estudiante OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16404)
-- Name: estudiante_id_estudiante_seq; Type: SEQUENCE; Schema: colegio_san_agustin; Owner: postgres
--

CREATE SEQUENCE colegio_san_agustin.estudiante_id_estudiante_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE colegio_san_agustin.estudiante_id_estudiante_seq OWNER TO postgres;

--
-- TOC entry 5115 (class 0 OID 0)
-- Dependencies: 222
-- Name: estudiante_id_estudiante_seq; Type: SEQUENCE OWNED BY; Schema: colegio_san_agustin; Owner: postgres
--

ALTER SEQUENCE colegio_san_agustin.estudiante_id_estudiante_seq OWNED BY colegio_san_agustin.estudiante.id_estudiante;


--
-- TOC entry 229 (class 1259 OID 16465)
-- Name: matricula; Type: TABLE; Schema: colegio_san_agustin; Owner: postgres
--

CREATE TABLE colegio_san_agustin.matricula (
    id_matricula integer NOT NULL,
    id_estudiante integer NOT NULL,
    id_curso integer NOT NULL,
    fecha_matricula date DEFAULT CURRENT_DATE,
    estado character varying(20) NOT NULL,
    promedio_final numeric(3,2) DEFAULT 0.00,
    CONSTRAINT matricula_estado_check CHECK (((estado)::text = ANY ((ARRAY['Inscrita'::character varying, 'Anulada'::character varying, 'Finalizada'::character varying])::text[])))
);


ALTER TABLE colegio_san_agustin.matricula OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 16464)
-- Name: matricula_id_matricula_seq; Type: SEQUENCE; Schema: colegio_san_agustin; Owner: postgres
--

CREATE SEQUENCE colegio_san_agustin.matricula_id_matricula_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE colegio_san_agustin.matricula_id_matricula_seq OWNER TO postgres;

--
-- TOC entry 5116 (class 0 OID 0)
-- Dependencies: 228
-- Name: matricula_id_matricula_seq; Type: SEQUENCE OWNED BY; Schema: colegio_san_agustin; Owner: postgres
--

ALTER SEQUENCE colegio_san_agustin.matricula_id_matricula_seq OWNED BY colegio_san_agustin.matricula.id_matricula;


--
-- TOC entry 233 (class 1259 OID 16521)
-- Name: v_boletinestudiantilconsolidado; Type: VIEW; Schema: colegio_san_agustin; Owner: postgres
--

CREATE VIEW colegio_san_agustin.v_boletinestudiantilconsolidado AS
 SELECT (((e.nombres)::text || ' '::text) || (e.apellidos)::text) AS estudiante,
    a.nombre AS asignatura,
    cg.periodo_lectivo,
    string_agg(((('Corte '::text || c.periodo_corte) || ': '::text) || c.nota_obtenida), ', '::text ORDER BY c.periodo_corte) AS calificaciones_por_corte,
    m.promedio_final AS promedio_acumulado,
        CASE
            WHEN (m.promedio_final >= 3.0) THEN 'Aprobado'::text
            ELSE 'Reprobado'::text
        END AS estado_aprobatorio
   FROM ((((colegio_san_agustin.matricula m
     JOIN colegio_san_agustin.estudiante e ON ((m.id_estudiante = e.id_estudiante)))
     JOIN colegio_san_agustin.curso_grupo cg ON ((m.id_curso = cg.id_curso)))
     JOIN colegio_san_agustin.asignatura a ON ((cg.id_asignatura = a.id_asignatura)))
     LEFT JOIN colegio_san_agustin.calificacion c ON ((m.id_matricula = c.id_matricula)))
  GROUP BY e.nombres, e.apellidos, a.nombre, cg.periodo_lectivo, m.promedio_final;


ALTER VIEW colegio_san_agustin.v_boletinestudiantilconsolidado OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 16526)
-- Name: v_cargadocenteyrendimiento; Type: VIEW; Schema: colegio_san_agustin; Owner: postgres
--

CREATE VIEW colegio_san_agustin.v_cargadocenteyrendimiento AS
SELECT
    NULL::text AS docente,
    NULL::character varying(20) AS periodo_lectivo,
    NULL::bigint AS numero_de_cursos,
    NULL::bigint AS total_estudiantes,
    NULL::numeric AS promedio_general,
    NULL::numeric AS tasa_aprobacion_porcentaje;


ALTER VIEW colegio_san_agustin.v_cargadocenteyrendimiento OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 16516)
-- Name: v_cursosdisponiblesycupo; Type: VIEW; Schema: colegio_san_agustin; Owner: postgres
--

CREATE VIEW colegio_san_agustin.v_cursosdisponiblesycupo AS
 SELECT a.codigo_materia,
    a.nombre AS asignatura,
    a.grado,
    cg.grupo,
    (((d.nombres)::text || ' '::text) || (d.apellidos)::text) AS docente,
    cg.cupo_maximo,
    (cg.cupo_maximo - cg.cupo_disponible) AS inscritos_totales,
    cg.cupo_disponible
   FROM ((colegio_san_agustin.curso_grupo cg
     JOIN colegio_san_agustin.asignatura a ON ((cg.id_asignatura = a.id_asignatura)))
     JOIN colegio_san_agustin.docente d ON ((cg.id_docente = d.id_docente)))
  WHERE (cg.cupo_disponible > 0);


ALTER VIEW colegio_san_agustin.v_cursosdisponiblesycupo OWNER TO postgres;

--
-- TOC entry 4900 (class 2604 OID 16424)
-- Name: asignatura id_asignatura; Type: DEFAULT; Schema: colegio_san_agustin; Owner: postgres
--

ALTER TABLE ONLY colegio_san_agustin.asignatura ALTER COLUMN id_asignatura SET DEFAULT nextval('colegio_san_agustin.asignatura_id_asignatura_seq'::regclass);


--
-- TOC entry 4905 (class 2604 OID 16492)
-- Name: calificacion id_calificacion; Type: DEFAULT; Schema: colegio_san_agustin; Owner: postgres
--

ALTER TABLE ONLY colegio_san_agustin.calificacion ALTER COLUMN id_calificacion SET DEFAULT nextval('colegio_san_agustin.calificacion_id_calificacion_seq'::regclass);


--
-- TOC entry 4901 (class 2604 OID 16441)
-- Name: curso_grupo id_curso; Type: DEFAULT; Schema: colegio_san_agustin; Owner: postgres
--

ALTER TABLE ONLY colegio_san_agustin.curso_grupo ALTER COLUMN id_curso SET DEFAULT nextval('colegio_san_agustin.curso_grupo_id_curso_seq'::regclass);


--
-- TOC entry 4897 (class 2604 OID 16390)
-- Name: docente id_docente; Type: DEFAULT; Schema: colegio_san_agustin; Owner: postgres
--

ALTER TABLE ONLY colegio_san_agustin.docente ALTER COLUMN id_docente SET DEFAULT nextval('colegio_san_agustin.docente_id_docente_seq'::regclass);


--
-- TOC entry 4899 (class 2604 OID 16408)
-- Name: estudiante id_estudiante; Type: DEFAULT; Schema: colegio_san_agustin; Owner: postgres
--

ALTER TABLE ONLY colegio_san_agustin.estudiante ALTER COLUMN id_estudiante SET DEFAULT nextval('colegio_san_agustin.estudiante_id_estudiante_seq'::regclass);


--
-- TOC entry 4902 (class 2604 OID 16468)
-- Name: matricula id_matricula; Type: DEFAULT; Schema: colegio_san_agustin; Owner: postgres
--

ALTER TABLE ONLY colegio_san_agustin.matricula ALTER COLUMN id_matricula SET DEFAULT nextval('colegio_san_agustin.matricula_id_matricula_seq'::regclass);


--
-- TOC entry 5099 (class 0 OID 16421)
-- Dependencies: 225
-- Data for Name: asignatura; Type: TABLE DATA; Schema: colegio_san_agustin; Owner: postgres
--

COPY colegio_san_agustin.asignatura (id_asignatura, codigo_materia, nombre, grado, intensidad_horaria, descripcion) FROM stdin;
1	MAT6	Matemáticas Básicas	6°	5	Introducción al álgebra
2	CIE6	Ciencias Naturales	6°	4	Biología celular básica
3	HUM7	Historia	7°	3	Historia medieval
4	FIS10	Física	10°	4	Mecánica clásica
5	QUI10	Química	10°	4	Química inorgánica
6	ING11	Inglés Avanzado	11°	5	Preparación pruebas saber
7	TEC9	Sistemas	9°	2	Lógica y algoritmos
8	ART8	Artes Plásticas	8°	2	Técnicas de pintura
9	DEP6	Educación Física	6°	2	Atletismo
10	FIL11	Filosofía	11°	3	Filosofía moderna
\.


--
-- TOC entry 5105 (class 0 OID 16489)
-- Dependencies: 231
-- Data for Name: calificacion; Type: TABLE DATA; Schema: colegio_san_agustin; Owner: postgres
--

COPY colegio_san_agustin.calificacion (id_calificacion, id_matricula, periodo_corte, porcentaje_peso, nota_obtenida, observaciones) FROM stdin;
1	1	1	25.00	4.00	Buen inicio
2	1	2	25.00	4.50	Mejora continua
3	2	1	30.00	3.00	Debe participar más
4	3	1	50.00	5.00	Excelente
5	4	1	25.00	2.00	Faltó a clase
6	5	1	25.00	4.20	Buen trabajo
7	6	1	25.00	3.50	Regular
8	7	1	20.00	4.80	Destacado
9	8	1	30.00	3.90	Bien
10	9	1	50.00	4.10	Creativo
\.


--
-- TOC entry 5101 (class 0 OID 16438)
-- Dependencies: 227
-- Data for Name: curso_grupo; Type: TABLE DATA; Schema: colegio_san_agustin; Owner: postgres
--

COPY colegio_san_agustin.curso_grupo (id_curso, id_asignatura, id_docente, periodo_lectivo, grupo, cupo_maximo, cupo_disponible, aula_asignada) FROM stdin;
10	10	10	2026-I	A	30	30	Aula 103
1	1	1	2026-II	A	30	28	Aula 101
2	2	2	2026-II	A	25	24	Lab 1
3	3	3	2026-II	B	30	29	Aula 102
4	4	4	2026-II	A	20	19	Lab 2
5	5	5	2026-II	A	20	19	Lab 3
6	6	8	2026-II	C	35	34	Audiovisuales
7	7	9	2026-II	A	20	19	Sala Info
8	8	7	2026-II	B	25	24	Taller 1
9	9	6	2026-II	A	40	39	Cancha
\.


--
-- TOC entry 5095 (class 0 OID 16387)
-- Dependencies: 221
-- Data for Name: docente; Type: TABLE DATA; Schema: colegio_san_agustin; Owner: postgres
--

COPY colegio_san_agustin.docente (id_docente, documento_identidad, nombres, apellidos, especialidad, telefono, email_institucional, activo) FROM stdin;
1	1001	Carlos	Gómez	Matemáticas	300111	carlos@agustin.edu	t
2	1002	Lucía	Martínez	Ciencias	300112	lucia@agustin.edu	t
3	1003	Miguel	Pérez	Humanidades	300113	miguel@agustin.edu	t
4	1004	Ana	Rojas	Física	300114	ana@agustin.edu	t
5	1005	Juan	Díaz	Química	300115	juan@agustin.edu	t
6	1006	María	López	Deportes	300116	maria@agustin.edu	t
7	1007	David	Suárez	Artes	300117	david@agustin.edu	t
8	1008	Laura	García	Inglés	300118	laura@agustin.edu	t
9	1009	Jorge	Castro	Tecnología	300119	jorge@agustin.edu	t
10	1010	Diana	Vega	Filosofía	300120	diana@agustin.edu	f
\.


--
-- TOC entry 5097 (class 0 OID 16405)
-- Dependencies: 223
-- Data for Name: estudiante; Type: TABLE DATA; Schema: colegio_san_agustin; Owner: postgres
--

COPY colegio_san_agustin.estudiante (id_estudiante, documento_identidad, nombres, apellidos, fecha_nacimiento, email_acudiente, telefono_acudiente, estado_academico) FROM stdin;
1	2001	Andrés	Muzu	2004-10-14	papa_andres@mail.com	3102221	Activo
2	2002	Sofia	Ruiz	2005-02-10	mama_sofia@mail.com	3102222	Activo
3	2003	Felipe	Luna	2004-05-20	papa_felipe@mail.com	3102223	Activo
4	2004	Camila	Cruz	2006-08-15	mama_camila@mail.com	3102224	Activo
5	2005	Daniel	Mora	2005-11-30	papa_daniel@mail.com	3102225	Retirado
6	2006	Valeria	Páez	2004-12-05	mama_valeria@mail.com	3102226	Activo
7	2007	Esteban	Ríos	2003-03-25	papa_esteban@mail.com	3102227	Graduado
8	2008	Paula	Gil	2006-01-18	mama_paula@mail.com	3102228	Activo
9	2009	Mateo	Sol	2005-07-22	papa_mateo@mail.com	3102229	Activo
10	2010	Isabella	Soto	2006-09-10	mama_isabella@mail.com	3102230	Activo
\.


--
-- TOC entry 5103 (class 0 OID 16465)
-- Dependencies: 229
-- Data for Name: matricula; Type: TABLE DATA; Schema: colegio_san_agustin; Owner: postgres
--

COPY colegio_san_agustin.matricula (id_matricula, id_estudiante, id_curso, fecha_matricula, estado, promedio_final) FROM stdin;
10	2	9	2026-10-27	Inscrita	0.00
1	1	1	2026-10-27	Inscrita	2.13
2	2	1	2026-10-27	Inscrita	0.90
3	3	2	2026-10-27	Inscrita	2.50
4	4	3	2026-10-27	Inscrita	0.50
5	6	4	2026-10-27	Inscrita	1.05
6	8	5	2026-10-27	Inscrita	0.88
7	9	6	2026-10-27	Inscrita	0.96
8	10	7	2026-10-27	Inscrita	1.17
9	1	8	2026-10-27	Inscrita	2.05
\.


--
-- TOC entry 5117 (class 0 OID 0)
-- Dependencies: 224
-- Name: asignatura_id_asignatura_seq; Type: SEQUENCE SET; Schema: colegio_san_agustin; Owner: postgres
--

SELECT pg_catalog.setval('colegio_san_agustin.asignatura_id_asignatura_seq', 10, true);


--
-- TOC entry 5118 (class 0 OID 0)
-- Dependencies: 230
-- Name: calificacion_id_calificacion_seq; Type: SEQUENCE SET; Schema: colegio_san_agustin; Owner: postgres
--

SELECT pg_catalog.setval('colegio_san_agustin.calificacion_id_calificacion_seq', 10, true);


--
-- TOC entry 5119 (class 0 OID 0)
-- Dependencies: 226
-- Name: curso_grupo_id_curso_seq; Type: SEQUENCE SET; Schema: colegio_san_agustin; Owner: postgres
--

SELECT pg_catalog.setval('colegio_san_agustin.curso_grupo_id_curso_seq', 10, true);


--
-- TOC entry 5120 (class 0 OID 0)
-- Dependencies: 220
-- Name: docente_id_docente_seq; Type: SEQUENCE SET; Schema: colegio_san_agustin; Owner: postgres
--

SELECT pg_catalog.setval('colegio_san_agustin.docente_id_docente_seq', 10, true);


--
-- TOC entry 5121 (class 0 OID 0)
-- Dependencies: 222
-- Name: estudiante_id_estudiante_seq; Type: SEQUENCE SET; Schema: colegio_san_agustin; Owner: postgres
--

SELECT pg_catalog.setval('colegio_san_agustin.estudiante_id_estudiante_seq', 10, true);


--
-- TOC entry 5122 (class 0 OID 0)
-- Dependencies: 228
-- Name: matricula_id_matricula_seq; Type: SEQUENCE SET; Schema: colegio_san_agustin; Owner: postgres
--

SELECT pg_catalog.setval('colegio_san_agustin.matricula_id_matricula_seq', 10, true);


--
-- TOC entry 4927 (class 2606 OID 16436)
-- Name: asignatura asignatura_codigo_materia_key; Type: CONSTRAINT; Schema: colegio_san_agustin; Owner: postgres
--

ALTER TABLE ONLY colegio_san_agustin.asignatura
    ADD CONSTRAINT asignatura_codigo_materia_key UNIQUE (codigo_materia);


--
-- TOC entry 4929 (class 2606 OID 16434)
-- Name: asignatura asignatura_pkey; Type: CONSTRAINT; Schema: colegio_san_agustin; Owner: postgres
--

ALTER TABLE ONLY colegio_san_agustin.asignatura
    ADD CONSTRAINT asignatura_pkey PRIMARY KEY (id_asignatura);


--
-- TOC entry 4935 (class 2606 OID 16504)
-- Name: calificacion calificacion_pkey; Type: CONSTRAINT; Schema: colegio_san_agustin; Owner: postgres
--

ALTER TABLE ONLY colegio_san_agustin.calificacion
    ADD CONSTRAINT calificacion_pkey PRIMARY KEY (id_calificacion);


--
-- TOC entry 4931 (class 2606 OID 16453)
-- Name: curso_grupo curso_grupo_pkey; Type: CONSTRAINT; Schema: colegio_san_agustin; Owner: postgres
--

ALTER TABLE ONLY colegio_san_agustin.curso_grupo
    ADD CONSTRAINT curso_grupo_pkey PRIMARY KEY (id_curso);


--
-- TOC entry 4917 (class 2606 OID 16401)
-- Name: docente docente_documento_identidad_key; Type: CONSTRAINT; Schema: colegio_san_agustin; Owner: postgres
--

ALTER TABLE ONLY colegio_san_agustin.docente
    ADD CONSTRAINT docente_documento_identidad_key UNIQUE (documento_identidad);


--
-- TOC entry 4919 (class 2606 OID 16403)
-- Name: docente docente_email_institucional_key; Type: CONSTRAINT; Schema: colegio_san_agustin; Owner: postgres
--

ALTER TABLE ONLY colegio_san_agustin.docente
    ADD CONSTRAINT docente_email_institucional_key UNIQUE (email_institucional);


--
-- TOC entry 4921 (class 2606 OID 16399)
-- Name: docente docente_pkey; Type: CONSTRAINT; Schema: colegio_san_agustin; Owner: postgres
--

ALTER TABLE ONLY colegio_san_agustin.docente
    ADD CONSTRAINT docente_pkey PRIMARY KEY (id_docente);


--
-- TOC entry 4923 (class 2606 OID 16419)
-- Name: estudiante estudiante_documento_identidad_key; Type: CONSTRAINT; Schema: colegio_san_agustin; Owner: postgres
--

ALTER TABLE ONLY colegio_san_agustin.estudiante
    ADD CONSTRAINT estudiante_documento_identidad_key UNIQUE (documento_identidad);


--
-- TOC entry 4925 (class 2606 OID 16417)
-- Name: estudiante estudiante_pkey; Type: CONSTRAINT; Schema: colegio_san_agustin; Owner: postgres
--

ALTER TABLE ONLY colegio_san_agustin.estudiante
    ADD CONSTRAINT estudiante_pkey PRIMARY KEY (id_estudiante);


--
-- TOC entry 4933 (class 2606 OID 16477)
-- Name: matricula matricula_pkey; Type: CONSTRAINT; Schema: colegio_san_agustin; Owner: postgres
--

ALTER TABLE ONLY colegio_san_agustin.matricula
    ADD CONSTRAINT matricula_pkey PRIMARY KEY (id_matricula);


--
-- TOC entry 5093 (class 2618 OID 16529)
-- Name: v_cargadocenteyrendimiento _RETURN; Type: RULE; Schema: colegio_san_agustin; Owner: postgres
--

CREATE OR REPLACE VIEW colegio_san_agustin.v_cargadocenteyrendimiento AS
 SELECT (((d.nombres)::text || ' '::text) || (d.apellidos)::text) AS docente,
    cg.periodo_lectivo,
    count(DISTINCT cg.id_curso) AS numero_de_cursos,
    count(m.id_matricula) AS total_estudiantes,
    COALESCE(round(avg(m.promedio_final), 2), (0)::numeric) AS promedio_general,
    COALESCE(round((((sum(
        CASE
            WHEN (m.promedio_final >= 3.0) THEN 1
            ELSE 0
        END))::numeric / (NULLIF(count(m.id_matricula), 0))::numeric) * (100)::numeric), 2), (0)::numeric) AS tasa_aprobacion_porcentaje
   FROM ((colegio_san_agustin.docente d
     JOIN colegio_san_agustin.curso_grupo cg ON ((d.id_docente = cg.id_docente)))
     LEFT JOIN colegio_san_agustin.matricula m ON (((cg.id_curso = m.id_curso) AND ((m.estado)::text <> 'Anulada'::text))))
  GROUP BY d.id_docente, cg.periodo_lectivo;


--
-- TOC entry 4943 (class 2620 OID 16515)
-- Name: calificacion tr_calcularpromediofinal; Type: TRIGGER; Schema: colegio_san_agustin; Owner: postgres
--

CREATE TRIGGER tr_calcularpromediofinal AFTER INSERT OR UPDATE ON colegio_san_agustin.calificacion FOR EACH ROW EXECUTE FUNCTION colegio_san_agustin.fn_calcular_promedio();


--
-- TOC entry 4941 (class 2620 OID 16513)
-- Name: matricula tr_restaurarcupoporanulacion; Type: TRIGGER; Schema: colegio_san_agustin; Owner: postgres
--

CREATE TRIGGER tr_restaurarcupoporanulacion AFTER UPDATE ON colegio_san_agustin.matricula FOR EACH ROW EXECUTE FUNCTION colegio_san_agustin.fn_restaurar_cupo();


--
-- TOC entry 4942 (class 2620 OID 16511)
-- Name: matricula tr_validarydescontarcupo; Type: TRIGGER; Schema: colegio_san_agustin; Owner: postgres
--

CREATE TRIGGER tr_validarydescontarcupo BEFORE INSERT ON colegio_san_agustin.matricula FOR EACH ROW EXECUTE FUNCTION colegio_san_agustin.fn_validar_descontar_cupo();


--
-- TOC entry 4940 (class 2606 OID 16505)
-- Name: calificacion calificacion_id_matricula_fkey; Type: FK CONSTRAINT; Schema: colegio_san_agustin; Owner: postgres
--

ALTER TABLE ONLY colegio_san_agustin.calificacion
    ADD CONSTRAINT calificacion_id_matricula_fkey FOREIGN KEY (id_matricula) REFERENCES colegio_san_agustin.matricula(id_matricula);


--
-- TOC entry 4936 (class 2606 OID 16454)
-- Name: curso_grupo curso_grupo_id_asignatura_fkey; Type: FK CONSTRAINT; Schema: colegio_san_agustin; Owner: postgres
--

ALTER TABLE ONLY colegio_san_agustin.curso_grupo
    ADD CONSTRAINT curso_grupo_id_asignatura_fkey FOREIGN KEY (id_asignatura) REFERENCES colegio_san_agustin.asignatura(id_asignatura);


--
-- TOC entry 4937 (class 2606 OID 16459)
-- Name: curso_grupo curso_grupo_id_docente_fkey; Type: FK CONSTRAINT; Schema: colegio_san_agustin; Owner: postgres
--

ALTER TABLE ONLY colegio_san_agustin.curso_grupo
    ADD CONSTRAINT curso_grupo_id_docente_fkey FOREIGN KEY (id_docente) REFERENCES colegio_san_agustin.docente(id_docente);


--
-- TOC entry 4938 (class 2606 OID 16483)
-- Name: matricula matricula_id_curso_fkey; Type: FK CONSTRAINT; Schema: colegio_san_agustin; Owner: postgres
--

ALTER TABLE ONLY colegio_san_agustin.matricula
    ADD CONSTRAINT matricula_id_curso_fkey FOREIGN KEY (id_curso) REFERENCES colegio_san_agustin.curso_grupo(id_curso);


--
-- TOC entry 4939 (class 2606 OID 16478)
-- Name: matricula matricula_id_estudiante_fkey; Type: FK CONSTRAINT; Schema: colegio_san_agustin; Owner: postgres
--

ALTER TABLE ONLY colegio_san_agustin.matricula
    ADD CONSTRAINT matricula_id_estudiante_fkey FOREIGN KEY (id_estudiante) REFERENCES colegio_san_agustin.estudiante(id_estudiante);


-- Completed on 2026-10-27 12:05:56

--
-- PostgreSQL database dump complete
--

\unrestrict Rkaa5Ij8VKQmgWER72MEgQmZ2WAJhOYoiLGgEfvELTPupGqbquuqBfeBr0IH937

