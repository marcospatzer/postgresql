CREATE OR REPLACE FUNCTION public.prc_user (
  p_usuario bigint
)
RETURNS varchar AS
$body$
declare
v_usuario   VARCHAR(30);
v_procpid   BIGINT;
v_contador  INTEGER;

c_usuario cursor is
select cdescriusuar
  from sisusuar
 where nnumerousuar = p_usuario;

c_procpid cursor is
SELECT procpid
  FROM pg_stat_activity
 WHERE datname = current_database()
   AND usename = session_user
   AND client_addr = inet_client_addr()
   AND client_port = inet_client_port();

begin
  open  c_usuario;
  fetch c_usuario into v_usuario;
  close c_usuario;

  open  c_procpid;
  fetch c_procpid into v_procpid;
  close c_procpid;

  -- apaga registros que nao estao mais logados 
  delete from tmpuser
   where procpid not in (select procpid
                           from pg_stat_activity
                          where datname = current_database());  

  delete from tmpuser
   where procpid = v_procpid;

  INSERT INTO tmpuser VALUES (v_procpid, v_usuario);

  -- setar a sessao para SOMENTE LEITURA se o acesso estiver bloqueado
  select count(*)
    into v_contador
    from sisacess
   where dbloqueacess is not null;
  if v_contador > 0 then
     set default_transaction_read_only=on;
  end if;

  return v_usuario;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;