create table meta_franquia
(id_meta_vigente serial primary key, 
id_meta int references meta(id_meta), 
id_franquia int references franquia(id_franquia), 
eh_vigente boolean not null  default true);