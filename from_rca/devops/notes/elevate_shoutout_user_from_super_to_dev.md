use _so;
set @userEmail = 'shamin@recoverycoa.com';
set @entityType = 'App\\User';

select id into @superRoleId from roles where handle = 'super';
select id into @devRoleId from roles where handle = 'dev';
select id into @userId from users where email = @userEmail collate utf8mb4_unicode_ci;

insert into roles_assigned (role_id,entity_id,entity_type,team_id) values (@devRoleId,@userId,@entityType,'');
delete from roles_assigned where entity_id = @userId and role_id = @superRoleId and team_id = '';
