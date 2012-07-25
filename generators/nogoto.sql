
create table nodes
(
	item_id integer primary key,
	type text,
	text_lines text,
	marked integer,
	incount integer,
	incoming integer,
	outgoing integer,
	trucks text,
	leaves text,
	is_dummy integer,
	split integer,
	real_item integer
);

create table links
(
	link_id integer primary key,
	src integer,
	ordinal integer,
	dst integer,
	link_type text
);

create unique index links_by_src_ordinal on links(src, ordinal);
create index links_by_dst on links(dst);

create table visited
(
	key text primary key,
	state text
);

create table stack
(
	id integer primary key,
	state text,
	total integer
);

create index stack_by_total on stack(total);
