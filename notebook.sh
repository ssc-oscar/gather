#!/bin/bash
#echo "IRkernel::installspec()" | R --no-save
mkdir -p ~/.jupyter/
echo "c.NotebookApp.token = u''" >> ~/.jupyter/jupyter_notebook_config.py
jupyter notebook --no-browser --ip="*" &

