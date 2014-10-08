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
-- Name: capmasks; Type: TABLE; Schema: public; Owner: aaron; Tablespace: 
--

CREATE TABLE capmasks (
    id integer NOT NULL,
    wordid integer,
    capmask integer
);


ALTER TABLE public.capmasks OWNER TO aaron;

--
-- Name: capmasks_id_seq; Type: SEQUENCE; Schema: public; Owner: aaron
--

CREATE SEQUENCE capmasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.capmasks_id_seq OWNER TO aaron;

--
-- Name: capmasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: aaron
--

ALTER SEQUENCE capmasks_id_seq OWNED BY capmasks.id;


--
-- Name: chains; Type: TABLE; Schema: public; Owner: aaron; Tablespace: 
--

CREATE TABLE chains (
    id integer NOT NULL,
    wordid integer,
    textid integer,
    nextid integer,
    capid integer,
    space boolean
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
    name pg_catalog.text,
    server pg_catalog.text
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
-- Name: quotes; Type: TABLE; Schema: public; Owner: aaron; Tablespace: 
--

CREATE TABLE quotes (
    id integer NOT NULL,
    channelid integer,
    "time" timestamp without time zone DEFAULT now(),
    chain pg_catalog.text
);


ALTER TABLE public.quotes OWNER TO aaron;

--
-- Name: quotes_id_seq; Type: SEQUENCE; Schema: public; Owner: aaron
--

CREATE SEQUENCE quotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.quotes_id_seq OWNER TO aaron;

--
-- Name: quotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: aaron
--

ALTER SEQUENCE quotes_id_seq OWNED BY quotes.id;


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

ALTER TABLE ONLY capmasks ALTER COLUMN id SET DEFAULT nextval('capmasks_id_seq'::regclass);


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

ALTER TABLE ONLY quotes ALTER COLUMN id SET DEFAULT nextval('quotes_id_seq'::regclass);


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
-- Name: quotes_pkey; Type: CONSTRAINT; Schema: public; Owner: aaron; Tablespace: 
--

ALTER TABLE ONLY quotes
    ADD CONSTRAINT quotes_pkey PRIMARY KEY (id);


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
-- Name: chains_wordid_index; Type: INDEX; Schema: public; Owner: aaron; Tablespace: 
--

CREATE INDEX chains_wordid_index ON chains USING btree (wordid);


--
-- Name: chains_wordid_textid_index; Type: INDEX; Schema: public; Owner: aaron; Tablespace: 
--

CREATE INDEX chains_wordid_textid_index ON chains USING btree (wordid, textid);


--
-- Name: channels_name_index; Type: INDEX; Schema: public; Owner: aaron; Tablespace: 
--

CREATE INDEX channels_name_index ON channels USING btree (name);


--
-- Name: words_word_index; Type: INDEX; Schema: public; Owner: aaron; Tablespace: 
--

CREATE INDEX words_word_index ON words USING btree (word);


--
-- Name: text_id; Type: FK CONSTRAINT; Schema: public; Owner: aaron
--

ALTER TABLE ONLY chains
    ADD CONSTRAINT text_id FOREIGN KEY (textid) REFERENCES text(id);


--
-- Name: word_id; Type: FK CONSTRAINT; Schema: public; Owner: aaron
--

ALTER TABLE ONLY chains
    ADD CONSTRAINT word_id FOREIGN KEY (wordid) REFERENCES words(id);


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

