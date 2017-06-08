CREATE TABLE data(node_id varchar(128) not null, node_type varchar(128) not null, measure_type varchar(128) not null, measure_value varchar(128) not null, time datetime not null, PRIMARY KEY(node_id, measure_type, time));

CREATE TABLE loc(id varchar(254) not null, lat varchar(254) not null, longitude varchar(254) not null, PRIMARY KEY(id));
