-- Tabela de controle de acesso dos colaboradores.
--
-- Rode isto no SQL Editor do Supabase. Seguro rodar de novo mesmo já tendo
-- dados — os "drop policy if exists" cuidam de substituir as regras antigas.
--
-- MUDANÇA NESTA VERSÃO: a policy de INSERT pela chave anon foi REMOVIDA.
-- Antes, o próprio login.html criava o registro de "primeiro acesso"
-- direto no Supabase (só que sempre nascendo pendente, por uma regra de
-- CHECK). Agora esse registro nasce via função manage-access.js (ação
-- "ensure-login"), usando a service role key — o login não fala mais com
-- o Supabase direto em nenhum momento. Como não existe mais nenhum motivo
-- pra chave anon escrever nessa tabela, a policy de escrita simplesmente
-- não existe mais: só SELECT fica liberado pra anon.

create table if not exists public.usuarios_acesso (
  usuario text primary key,
  nome text,
  email text,
  tipo text check (tipo in ('admin','geral','individual') or tipo is null),
  aprovado boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.usuarios_acesso enable row level security;

-- Leitura pública: necessária para o painel admin listar todo mundo e para
-- a função manage-access conferir status/admin antes de gravar qualquer coisa.
drop policy if exists "leitura publica usuarios_acesso" on public.usuarios_acesso;
create policy "leitura publica usuarios_acesso"
on public.usuarios_acesso for select
to anon
using (true);

-- INSERT e UPDATE pela chave anon foram REMOVIDOS de propósito — não tem
-- mais nenhum caminho de escrita direto pela chave pública. Toda gravação
-- (primeiro acesso, aprovação, troca de tipo, revogação) passa pela função
-- manage-access.js, que usa a SERVICE ROLE KEY (nunca exposta no navegador).
drop policy if exists "insercao publica usuarios_acesso" on public.usuarios_acesso;
drop policy if exists "atualizacao publica usuarios_acesso" on public.usuarios_acesso;
