Create role Social;

Create user SocialApplication password 'socialapplication';

Create tablespace Social location '/data/postgresql/tablespace/social';

Create tablespace SocialBig location '/data/postgresql/tablespace/socialbig';

Grant create on tablespace SocialBig to Social;

Create database Social  owner Social encoding 'UTF8' tablespace Social;

