import os
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from sqlalchemy.orm import declarative_base

# Use SQLite for local development & testing according to architecture blueprint flexibility
# Can be replaced with PostgreSQL: 'postgresql+asyncpg://user:pass@localhost/dbname'
# Note FATE architecture specified PostgreSQL, but for immediate functional testing we use SQLite.
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./fate_db.sqlite3")

engine = create_async_engine(DATABASE_URL, echo=False)
AsyncSessionLocal = async_sessionmaker(bind=engine, expire_on_commit=False)

Base = declarative_base()

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session
