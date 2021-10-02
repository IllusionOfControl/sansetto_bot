from flask import current_app
from sansetto import get_application, models
from sansetto.database import engine, SessionLocal
import os
import rq
import pyvips


app = get_application()
app.app_context().push()


def _reduce_image(*, filename, input_path, output_path, quality, side_size):
    original_image_path = os.path.join(input_path, filename)
    processed_image_path = os.path.join(output_path, filename)
    image = pyvips.Image.new_from_file(original_image_path)
    if side_size < max(image.width, image.height):
        image = image.resize(side_size / max(image.width, image.height))
    image.jpegsave(processed_image_path, Q=quality)


def _calculate_aspect_ratio(width, height):
    def gcd(a, b):
        return a if b == 0 else gcd(b, a % b)

    r = gcd(width, height)
    x = int(width / r)
    y = int(height / r)

    return f"{x}:{y}"


def _get_image_dimensions(image_path):
    image = pyvips.Image.new_from_file(image_path)
    image_w = image.width
    image_h = image.height
    aspect = _calculate_aspect_ratio(image_w, image_h)
    return image_w, image_h, aspect


def process_image_task(image_id):
    db_session = SessionLocal()
    image = db_session.query(models.Image).get(image_id)
    if not image:
        return

    try:
        # Document
        _reduce_image(
            filename=image.filename,
            input_path=app.config["UPLOAD_FOLDER"],
            output_path=app.config["DOCUMENT_FOLDER"],
            quality=app.config["IMAGE_QUALITY"],
            side_size=app.config["MAX_IMAGE_SIDE"]
        )

        # Image
        _reduce_image(
            filename=image.filename,
            input_path=app.config["UPLOAD_FOLDER"],
            output_path=app.config["THUMBNAIL_FOLDER"],
            quality=app.config["THUMBNAIL_QUALITY"],
            side_size=app.config["MAX_THUMBNAIL_SIDE"]
        )

        image_path = os.path.join(app.config["DOCUMENT_FOLDER"], image.filename)
        width, height, aspect = _get_image_dimensions(image_path)
        image.width = width
        image.height = height
        image.aspect_ratio = aspect
        image.was_processed = True
        db_session.commit()
        os.remove(image_path)
    except pyvips.Error as e:
        image.is_invalid = True
        image.was_processed = True
        db_session.commit()
        current_app.logger.error('Exception', e.message)


def _send_image(filename):
    pass


def _send_document(filename):
    pass


def send_art(image_id):
    db_session = SessionLocal()
    image = db_session.query(models.Image).get(image_id)
    if not image:
        return


