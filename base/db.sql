--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: chains; Type: TABLE; Schema: public; Owner: aaron; Tablespace: 
--

CREATE TABLE chains (
    id integer NOT NULL,
    wordid integer,
    textid integer,
    nextwordid integer DEFAULT (-1)
);


ALTER TABLE public.chains OWNER TO aaron;

--
-- Name: chains_id_seq; Type: SEQUENCE; Schema: public; Owner: aaron
--

CREATE SEQUENCE chains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chains_id_seq OWNER TO aaron;

--
-- Name: chains_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: aaron
--

ALTER SEQUENCE chains_id_seq OWNED BY chains.id;


--
-- Name: channels; Type: TABLE; Schema: public; Owner: aaron; Tablespace: 
--

CREATE TABLE channels (
    id integer NOT NULL,
    name pg_catalog.text
);


ALTER TABLE public.channels OWNER TO aaron;

--
-- Name: channels_id_seq; Type: SEQUENCE; Schema: public; Owner: aaron
--

CREATE SEQUENCE channels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.channels_id_seq OWNER TO aaron;

--
-- Name: channels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: aaron
--

ALTER SEQUENCE channels_id_seq OWNED BY channels.id;


--
-- Name: sources; Type: TABLE; Schema: public; Owner: aaron; Tablespace: 
--

CREATE TABLE sources (
    id integer NOT NULL,
    type integer,
    channelid integer,
    userid integer
);


ALTER TABLE public.sources OWNER TO aaron;

--
-- Name: sources_id_seq; Type: SEQUENCE; Schema: public; Owner: aaron
--

CREATE SEQUENCE sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sources_id_seq OWNER TO aaron;

--
-- Name: sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: aaron
--

ALTER SEQUENCE sources_id_seq OWNED BY sources.id;


--
-- Name: test; Type: TABLE; Schema: public; Owner: aaron; Tablespace: 
--

CREATE TABLE test (
);


ALTER TABLE public.test OWNER TO aaron;

--
-- Name: text; Type: TABLE; Schema: public; Owner: aaron; Tablespace: 
--

CREATE TABLE text (
    id integer NOT NULL,
    sourceid integer,
    "time" integer,
    text pg_catalog.text
);


ALTER TABLE public.text OWNER TO aaron;

--
-- Name: text_id_seq; Type: SEQUENCE; Schema: public; Owner: aaron
--

CREATE SEQUENCE text_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.text_id_seq OWNER TO aaron;

--
-- Name: text_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: aaron
--

ALTER SEQUENCE text_id_seq OWNED BY text.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: aaron; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    hostmask pg_catalog.text,
    isadmin integer DEFAULT 0
);


ALTER TABLE public.users OWNER TO aaron;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: aaron
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO aaron;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: aaron
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: words; Type: TABLE; Schema: public; Owner: aaron; Tablespace: 
--

CREATE TABLE words (
    id integer NOT NULL,
    word pg_catalog.text
);


ALTER TABLE public.words OWNER TO aaron;

--
-- Name: words_id_seq; Type: SEQUENCE; Schema: public; Owner: aaron
--

CREATE SEQUENCE words_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.words_id_seq OWNER TO aaron;

--
-- Name: words_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: aaron
--

ALTER SEQUENCE words_id_seq OWNED BY words.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: aaron
--

ALTER TABLE ONLY chains ALTER COLUMN id SET DEFAULT nextval('chains_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: aaron
--

ALTER TABLE ONLY channels ALTER COLUMN id SET DEFAULT nextval('channels_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: aaron
--

ALTER TABLE ONLY sources ALTER COLUMN id SET DEFAULT nextval('sources_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: aaron
--

ALTER TABLE ONLY text ALTER COLUMN id SET DEFAULT nextval('text_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: aaron
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: aaron
--

ALTER TABLE ONLY words ALTER COLUMN id SET DEFAULT nextval('words_id_seq'::regclass);


--
-- Name: chains_pkey; Type: CONSTRAINT; Schema: public; Owner: aaron; Tablespace: 
--

ALTER TABLE ONLY chains
    ADD CONSTRAINT chains_pkey PRIMARY KEY (id);


--
-- Name: channels_pkey; Type: CONSTRAINT; Schema: public; Owner: aaron; Tablespace: 
--

ALTER TABLE ONLY channels
    ADD CONSTRAINT channels_pkey PRIMARY KEY (id);


--
-- Name: sources_pkey; Type: CONSTRAINT; Schema: public; Owner: aaron; Tablespace: 
--

ALTER TABLE ONLY sources
    ADD CONSTRAINT sources_pkey PRIMARY KEY (id);


--
-- Name: text_pkey; Type: CONSTRAINT; Schema: public; Owner: aaron; Tablespace: 
--

ALTER TABLE ONLY text
    ADD CONSTRAINT text_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: aaron; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: words_pkey; Type: CONSTRAINT; Schema: public; Owner: aaron; Tablespace: 
--

ALTER TABLE ONLY words
    ADD CONSTRAINT words_pkey PRIMARY KEY (id);


--
-- Name: words_word_index; Type: INDEX; Schema: public; Owner: aaron; Tablespace: 
--

CREATE INDEX words_word_index ON words USING btree (word);


--
-- Name: srcid; Type: FK CONSTRAINT; Schema: public; Owner: aaron
--

ALTER TABLE ONLY chains
    ADD CONSTRAINT srcid FOREIGN KEY (textid) REFERENCES text(id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

