from config import Config
from flask import Flask
from redis import Redis
from sqlalchemy.orm import scoped_session
import rq


def get_application(config=Config):
    application = Flask(__name__)
    application.config.from_object(config)

    from sansetto.database import engine, SessionLocal
    from sansetto import models
    models.Base.metadata.create_all(bind=engine)
    application.db = scoped_session(SessionLocal)

    @application.teardown_appcontext
    def teardown_db(error):
        application.db.remove()

    from sansetto.views import bp as bp_views

    application.register_blueprint(bp_views)

    application.redis = Redis()
    application.task_queue = rq.Queue("sansetto_bot_tasks", connection=application.redis)

    return application

