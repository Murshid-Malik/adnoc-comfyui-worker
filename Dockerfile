FROM runpod/worker-comfyui:5.10.0-base

# Use the newer commit recorded by the supplied workflow. The older loader
# metadata points to a schema without 'General Lite (170 MiB)' / AUTO dtype.
RUN git clone https://github.com/set-soft/ComfyUI-RemoveBackground_SET /comfyui/custom_nodes/ComfyUI-RemoveBackground_SET \
 && cd /comfyui/custom_nodes/ComfyUI-RemoveBackground_SET \
 && git checkout 879376ba9dd1aa2b186385ca88eb5f06edd12232
RUN comfy node install --exit-on-fail comfyui-rmbg@3.1.0 --mode remote
RUN git clone https://github.com/kijai/ComfyUI-KJNodes /comfyui/custom_nodes/ComfyUI-KJNodes \
 && cd /comfyui/custom_nodes/ComfyUI-KJNodes \
 && git checkout d7641533d6634eb05f8570c980fce8fc8528dc7b

# Install into the interpreter used by the inherited worker startup, preserving
# its installed CUDA torch family and transformers/hub compatibility boundaries.
RUN /opt/venv/bin/python -m pip freeze | grep -E '^(torch|torchvision|torchaudio)==' > /tmp/adnoc-constraints.txt \
 && printf 'transformers<5\nhuggingface-hub<1.0\n' >> /tmp/adnoc-constraints.txt \
 && for dir in ComfyUI-RemoveBackground_SET ComfyUI-RMBG ComfyUI-KJNodes; do \
      node_dir="$(find /comfyui/custom_nodes -mindepth 1 -maxdepth 1 -type d -iname "$dir")"; \
      if [ -z "$node_dir" ] || [ ! -f "$node_dir/requirements.txt" ]; then \
        echo "Missing or ambiguous requirements directory for $dir" >&2; \
        ls -la /comfyui/custom_nodes; exit 1; \
      fi; \
      echo "Installing requirements from $node_dir"; \
      /opt/venv/bin/python -m pip install -c /tmp/adnoc-constraints.txt -r "$node_dir/requirements.txt" || exit 1; \
    done

# Match this exact node version's RemBG model cache path and filename.
RUN mkdir -p /comfyui/models/RemBG \
 && wget --progress=dot:giga --tries=3 \
    -O /comfyui/models/RemBG/General-Lite.safetensors \
    https://huggingface.co/ZhengPeng7/BiRefNet_lite/resolve/main/model.safetensors \
 && /opt/venv/bin/python -c "from safetensors import safe_open; f=safe_open('/comfyui/models/RemBG/General-Lite.safetensors',framework='pt',device='cpu'); assert len(f.keys()) > 0"

COPY api-workflow.json /adnoc/api-workflow.json
COPY verify_nodes.py /adnoc/verify_nodes.py
RUN /opt/venv/bin/python /adnoc/verify_nodes.py

# Inherit /start.sh: starts ComfyUI and the RunPod queue worker.
# Capture and background images arrive with each request; no sample photos baked in.
