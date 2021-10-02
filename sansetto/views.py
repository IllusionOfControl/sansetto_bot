from flask import Blueprint, request, render_template, current_app
from werkzeug.utils import secure_filename
from sansetto.models import Image
from sansetto.utils import allowed_file
import uuid
import json
import os

bp = Blueprint('views', __name__)


@bp.route("/")
@bp.route("/index")
def index():
    return render_template("index.html")


@bp.post("/upload")
def upload():
    if 'image' not in request.files:
        return json.dumps({"success": False, "msg": "no file part"}), 400
    image_file = request.files['image']
    if image_file and allowed_file(image_file.filename):
        image = Image()
        image.filename = uuid.uuid4().hex
        image_file.save(os.path.join(current_app.config["UPLOAD_FOLDER"], image.filename))
        current_app.db.add(image)
        current_app.db.commit()
        current_app.task_queue.enqueue("sansetto.tasks.process_image_task", image.id)
        return json.dumps({"success": True}), 201
    return json.dumps({"success": False, "msg": "bad request"}), 400
