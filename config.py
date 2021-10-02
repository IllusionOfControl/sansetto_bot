import os

basedir = os.path.abspath(os.path.dirname(__file__))


class Config(object):
    DEBUG = True
    SECRET_KEY = "you-will-never-guess"
    DATABASE_URI = "sqlite:///" + os.path.join(basedir, "sansetto.db")
    REDIS_URL = "redis://localhost"
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}

    MAX_IMAGE_SIDE = 2500
    MAX_THUMBNAIL_SIDE = 800
    IMAGE_QUALITY = 95
    THUMBNAIL_QUALITY = 75

    UPLOAD_FOLDER = os.path.join(basedir + "/uploads")
    DOCUMENT_FOLDER = os.path.join(basedir + "/documents")
    THUMBNAIL_FOLDER = os.path.join(basedir + "/thumbnails")
    DELETE_IMAGE_AFTER_PROCESSING = True

    SANSETTO_TOKEN = os.getenv("SANSETTO_TOKEN")
    SANSETTO_CHAT_ID = os.getenv("SANSETTO_CHAT_ID")
