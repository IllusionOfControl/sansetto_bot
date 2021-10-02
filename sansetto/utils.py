from flask import current_app
from sansetto.models import Image


def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in current_app.config["ALLOWED_EXTENSIONS"]


def restore_task_queue():
    images_to_process = current_app.db.query(Image).filter_by(was_processed=False).all()
    images_to_send = current_app.db.query(Image).filter_by(was_processed=True, is_invalid=False, was_sent=False).all()

    for image in images_to_process:
        current_app.task_queue.enqueue("sansetto.tasks.process_image_task", image.id)

    for image in images_to_send:
        current_app.task_queue.enqueue("sansetto.tasks.send_image", image.id)
