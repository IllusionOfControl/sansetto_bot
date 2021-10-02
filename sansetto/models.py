from flask import current_app
from sqlalchemy import Column, Integer, String, Enum, Boolean, DateTime
from sansetto.database import Base
import datetime
import enum
import uuid
import redis
import rq


def gen_random_uuid_as_str(self):
    return uuid.uuid4().hex


class ImageOrientationEnum(enum.Enum):
    vertical = 0
    horizontal = 1


class Image(Base):
    __tablename__ = "images"

    id = Column(Integer, primary_key=True, index=True)
    filename = Column(String(16), default=gen_random_uuid_as_str, nullable=False)
    orientation = Column(Enum(ImageOrientationEnum))
    image_width = Column(Integer, nullable=False, default=0)
    image_height = Column(Integer, nullable=False, default=0)
    aspect_ratio = Column(String(9), nullable=False, default="0:0")
    upload_timestamp = Column(DateTime, nullable=False, default=datetime.datetime.now())
    sent_timestamp = Column(DateTime)
    was_processed = Column(Boolean, nullable=False, default=False)
    was_sent = Column(Boolean, nullable=False, default=False)
    is_invalid = Column(Boolean, nullable=False, default=False)


# class Task(Base):
#     __tablename__ = "tasks"
#
#     id = Column(Integer, primary_key=True, index=True)
#     uuid = Column(String(16), default=gen_random_uuid_as_str, nullable=False)
#     name = Column(String(128), index=True)
#     args = Column(String, nullable=True, default="")
#     complete = Column(Boolean, default=False)
#     created_at = Column(DateTime, default=datetime.datetime.now())
#     completed_on = Column(DateTime)
