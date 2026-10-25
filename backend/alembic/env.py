from alembic import context
from app.db.session import get_engine

# Baseline is SQL-first. Map all existing tables before enabling autogenerate.
if getattr(context.config.cmd_opts, "autogenerate", False):
    raise RuntimeError("Map all 9 tables first; see docs/DATABASE_WORKFLOW.md")


def run_migrations_online() -> None:
    with get_engine().connect() as connection:
        context.configure(connection=connection, target_metadata=None)
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    raise RuntimeError("Baseline checks existing tables; use an online disposable DEV database")
else:
    run_migrations_online()
