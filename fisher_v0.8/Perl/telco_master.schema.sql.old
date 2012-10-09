-- SQL schema declarations for tables that are
-- "global" to all telephone collection projects.
--

-- Primary tables: "telco_" prefix in table name indicates
--                 data shared by all collection create

create table IF NOT EXISTS telco_subjects (
       subj_id		int not null auto_increment,
-- identification fields:
       fname		varchar(30),
       lname		varchar(30),
       ssn		varchar(12),
-- contact fields:
       email		varchar(40),
       street		varchar(50),
       apt		varchar(10),
       city		varchar(30),
       state varchar(30), zip_code varchar(16), -- null for foreigners
       province varchar(30), post_code varchar(20), -- null for domestics
       country		varchar(40),
       contact_phone	varchar(20),
       contact_time	varchar(30),
-- demographic fields:
       gender		enum('M','F','B','G','X'),
       age		tinyint unsigned,
       edu_years	tinyint unsigned,
       native_lang	varchar(25),
       second_lang	varchar(25),
       other_langs	varchar(250),
       country_born	varchar(30),
       country_raised	varchar(30),
       state_raised	varchar(30),
       city_raised	varchar(30),
       region		varchar(30),
       occupation	varchar(80),
-- history/tracking fields:
       recruiter	varchar(12),
       recruit_date	date,
       enroll_data	varchar(250),
       referred_by	varchar(100),
       latest_remark	varchar(250),
       sut		datetime,       -- skip-until-time
       cip              enum('Y','N'),  -- call-in-progress
       primary key (subj_id)
) TYPE = InnoDB;

create table IF NOT EXISTS telco_subj_remarks ( -- keep remarks history per subject
       subj_id		int not null,
       remark_date	datetime,
       remark		varchar(250),
       entered_by	varchar(16),
       index (subj_id),
       foreign key (subj_id) references telco_subjects(subj_id)
) TYPE = InnoDB;

create table IF NOT EXISTS telco_phones (
       phone_id		int not null auto_increment,
       subj_id		int not null,
       phone_number	varchar(20) not null,
       phone_type	varchar(20),
       phone_svc	varchar(40),
       primary key (phone_id),
       index (subj_id),
       foreign key (subj_id) references telco_subjects(subj_id)
) TYPE = InnoDB;

create table IF NOT EXISTS telco_available (
       subj_id		int not null,
       phone_id		int not null,	
       tz		tinyint not null,		
       avstring		varchar(96),
       index (subj_id),
       foreign key (subj_id) references telco_subjects(subj_id),
       index (phone_id),
       foreign key (phone_id) references telco_phones(phone_id)
) TYPE = InnoDB;


-- Project-specific tables:

create table IF NOT EXISTS lvd_subj (
       pin		smallint not null,
       subj_id		int not null,
       active		char(1),
       active_date	datetime,
       deactive_date	datetime,
       calls_done	smallint unsigned,
       max_allowed	smallint unsigned,
       group_id		varchar(20), -- to group by language
       subgroup_id	varchar(20), -- to group specific partner pairs together
       used_for		varchar(16), -- for partitioning (train/dev/eval)
       primary key (pin),
       index (subj_id),
       foreign key (subj_id) references telco_subjects(subj_id)
) TYPE = InnoDB;

create table IF NOT EXISTS lvd_topics (
       topic_id		int not null auto_increment,
       topic_descr	varchar(250),
       topic_file	varchar(80),
       summ_file	varchar(80),
       tod_yn		enum('Y', 'N'),  -- "Y" if this topic should be used today
       primary key (topic_id)
) TYPE = InnoDB;

create table IF NOT EXISTS lvd_io_calls (
       side_id		int not null auto_increment,
       subj_id		int,
       phone_id		int,
       phonetype	char(1),
       phoneset		char(1),
       io_start		datetime not null, -- time at which line went off-hook
       io_end		datetime not null, -- time at which call terminated
       io_phnum		varchar(25),  -- number dialed out or incoming ANI
       io_proc_id	tinyint unsigned,
       io_line_id	tinyint unsigned,
       io_length	smallint unsigned,     -- duration off-hook, in sec.
       io_hup_status	varchar(32),  -- cause/result of unbridged call termination
       bridged_to	int,  -- other io_side_id, null if io_hup_status is not null
       br_call_id	int,  -- references lvd_br_calls(call_id)
       primary key (side_id),
       index (subj_id),
       foreign key (subj_id) references lvd_subj(subj_id),
       index (phone_id),
       foreign key (phone_id) references telco_phones(phone_id)
) TYPE = InnoDB;

-- Notes: "io_" refers to "inbound/outbound": rows in this table
-- represent all single-line platform activity. i.e. all dial-ins and
-- all dial-outs.

create table IF NOT EXISTS lvd_br_calls (
       call_id		int not null auto_increment,
       cra_side_id	int not null,
       crb_side_id	int not null,
       topic_id		int,
       call_date	datetime not null,  -- time at which bridge was made
       runtime		smallint unsigned,
       fila		varchar(80),
       filb		varchar(80),
       filesiza		int unsigned,
       filesizb		int unsigned,
       hup_status	varchar(32), -- cause/result of bridged call termination
       sph_status	varchar(32), -- tracks speech file processing
       annot_status	varchar(32), -- tracks stages/outcomes of audit/annotation
       used_for		varchar(16), -- for partitioning (train/dev/eval)
       primary key (call_id),
       index (cra_side_id),
       foreign key (cra_side_id) references lvd_io_calls(side_id),
       index (crb_side_id),
       foreign key (crb_side_id) references lvd_io_calls(side_id),
       index (topic_id),
       foreign key (topic_id) references lvd_topics(topic_id),
) TYPE = InnoDB;

create table IF NOT EXISTS lvd_audit (
       call_id		int not null,
       auditor		varchar(12),
       audit_date	datetime,
       tech_prob	char(1),
       cra_sex		enum('M','F','B','G'),
       crb_sex		enum('M','F','B','G'),
       cra_sig		enum('G','A','U'),
       crb_sig		enum('G','A','U'),
       cra_cnv		enum('G','A','U'),
       crb_cnv		enum('G','A','U'),
       lang		varchar(20),
       index (call_id),
       foreign key (call_id) references lvd_br_calls(call_id)
) TYPE = InnoDB;

-- Notes: "_br_" refers to "bridged": rows in this table represent
-- all/only the calls that have been bridged.  Some projects may need
-- more "status" fields; the three given above are a bare minimum that
-- all projects should have.  Any added "_status" field should be one
-- that is needed for query selection or project reporting and is
-- logically distinct in scope from other status fields.  If a project
-- needs additional fields purely for inter-process communication on
-- the project platform, their scope should be made clear in the field
-- name (e.g. "ipc_*").

create table IF NOT EXISTS lvd_subj_pairs (  -- keeps track of who spoke to whom
       subj_id		int not null,
       spoke_to		int not null,
       call_id		int not null,
       index (subj_id),
       foreign key (subj_id) references telco_subjects(subj_id),
       index (spoke_to),
       foreign key (spoke_to) references telco_subjects(subj_id),
       index (call_id),
       foreign key (call_id) references lvd_br_calls(call_id)
) TYPE = InnoDB;

-- Note: for each successful call in the given project, we add two rows to
-- project_subj_pairs, one with each pin in the subj_id field; this will
-- allow the table to be indexed and queried on just the subj_id field

create table IF NOT EXISTS lvd_subj_payouts (
       subj_id		int not null,
       pay_date		date,
       amount		smallint unsigned,
       paid_by		varchar(24), -- staffer name
       paid_for		varchar(250), -- date-range, bonus types, etc.
       index (subj_id),
       foreign key (subj_id) references telco_subjects(subj_id)
) TYPE = InnoDB;
