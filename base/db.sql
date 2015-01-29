--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: selectchainleft(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION selectchainleft(bigint) RETURNS bigint
    LANGUAGE plpgsql
    AS $_$
          DECLARE
            maxsum BIGINT;
            res    BIGINT;
          BEGIN
            DROP TABLE IF EXISTS widcache_$1;
            CREATE TEMP TABLE widcache_$1 AS (
              SELECT nextchain,sum(count) OVER (ORDER BY nextchain) 
                FROM chains
                WHERE nextwid=$1
                ORDER BY nextchain
            );
            maxsum := ( SELECT max(sum) 
                     FROM widcache_$1 );
            res := ( SELECT nextchain
              FROM widcache_$1
              WHERE sum >= FLOOR(RANDOM() * maxsum)
              LIMIT 1 );

            RETURN res;
          ROLLBACK;
          END;
        $_$;


--
-- Name: selectchainright(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION selectchainright(bigint) RETURNS bigint
    LANGUAGE plpgsql
    AS $_$
          DECLARE
            maxsum BIGINT;
            res    BIGINT;
          BEGIN
            DROP TABLE IF EXISTS widcache_$1;
            CREATE TEMP TABLE widcache_$1 AS (
              SELECT id,sum(count) OVER (ORDER BY id) 
                FROM chains
                WHERE wid=$1
                ORDER BY id
            );
            maxsum := ( SELECT max(sum) 
                     FROM widcache_$1 );
            res := ( SELECT id
              FROM widcache_$1
              WHERE sum >= FLOOR(RANDOM() * maxsum)
              LIMIT 1 );

            RETURN res;
          ROLLBACK;
          END;
        $_$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: chains; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE chains (
    id integer NOT NULL,
    wid integer,
    nextwid integer,
    nextchain integer,
    count integer
);


--
-- Name: chains_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE chains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chains_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE chains_id_seq OWNED BY chains.id;


--
-- Name: channels; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE channels (
    id integer NOT NULL,
    name pg_catalog.text
);


--
-- Name: channels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE channels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: channels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE channels_id_seq OWNED BY channels.id;


--
-- Name: quotes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE quotes (
    id integer NOT NULL,
    channelid integer,
    "time" timestamp without time zone DEFAULT now(),
    chain pg_catalog.text
);


--
-- Name: quotes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE quotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE quotes_id_seq OWNED BY quotes.id;


--
-- Name: sources; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sources (
    id integer NOT NULL,
    type integer,
    channelid integer,
    userid integer
);


--
-- Name: sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sources_id_seq OWNED BY sources.id;


--
-- Name: text; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE text (
    id integer NOT NULL,
    sourceid integer,
    "time" integer,
    text pg_catalog.text,
    processed boolean DEFAULT false
);


--
-- Name: text_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE text_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: text_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE text_id_seq OWNED BY text.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    hostmask pg_catalog.text,
    isadmin integer DEFAULT 0
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: words; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE words (
    id integer NOT NULL,
    word pg_catalog.text
);


--
-- Name: words_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE words_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: words_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE words_id_seq OWNED BY words.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY chains ALTER COLUMN id SET DEFAULT nextval('chains_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY channels ALTER COLUMN id SET DEFAULT nextval('channels_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY quotes ALTER COLUMN id SET DEFAULT nextval('quotes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sources ALTER COLUMN id SET DEFAULT nextval('sources_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY text ALTER COLUMN id SET DEFAULT nextval('text_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY words ALTER COLUMN id SET DEFAULT nextval('words_id_seq'::regclass);


--
-- Name: channels_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY channels
    ADD CONSTRAINT channels_pkey PRIMARY KEY (id);


--
-- Name: quotes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY quotes
    ADD CONSTRAINT quotes_pkey PRIMARY KEY (id);


--
-- Name: sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sources
    ADD CONSTRAINT sources_pkey PRIMARY KEY (id);


--
-- Name: text_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY text
    ADD CONSTRAINT text_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: words_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY words
    ADD CONSTRAINT words_pkey PRIMARY KEY (id);


--
-- Name: chains_count; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX chains_count ON chains USING btree (count);


--
-- Name: chains_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX chains_id_index ON chains USING btree (id);


--
-- Name: chains_nextchain; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX chains_nextchain ON chains USING btree (nextchain);


--
-- Name: chains_nextwid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX chains_nextwid ON chains USING btree (nextwid);


--
-- Name: chains_wid_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX chains_wid_index ON chains USING btree (wid);


--
-- Name: chains_wid_nextwid_nextcid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX chains_wid_nextwid_nextcid ON chains USING btree (wid, nextwid, nextchain);


--
-- Name: channels_chanid_userid_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX channels_chanid_userid_index ON sources USING btree (channelid, userid);


--
-- Name: channels_name_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX channels_name_index ON channels USING btree (name);


--
-- Name: text_processed_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX text_processed_index ON text USING btree (processed);


--
-- Name: users_hostmask_hash_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_hostmask_hash_index ON users USING hash (hostmask);


--
-- Name: words_word_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX words_word_index ON words USING hash (word);


--
-- PostgreSQL database dump complete
--

