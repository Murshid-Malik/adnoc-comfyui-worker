# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.10.0-base

# install custom nodes into comfyui
RUN git clone https://github.com/set-soft/ComfyUI-RemoveBackground_SET /comfyui/custom_nodes/ComfyUI-RemoveBackground_SET && cd /comfyui/custom_nodes/ComfyUI-RemoveBackground_SET && (git checkout 4a1884d296e39e36c3b6f4c873c08ac9e7ce1294 2>/dev/null || (git fetch origin 4a1884d296e39e36c3b6f4c873c08ac9e7ce1294 --depth=1 && git checkout 4a1884d296e39e36c3b6f4c873c08ac9e7ce1294) || echo "WARN: commit 4a1884d296e39e36c3b6f4c873c08ac9e7ce1294 unreachable in https://github.com/set-soft/ComfyUI-RemoveBackground_SET, falling back to default branch HEAD")
RUN comfy node install --exit-on-fail comfyui-rmbg@3.1.0 --mode remote || (echo "WARN: comfyui-rmbg@3.1.0 unavailable in registry, falling back to latest" >&2 && comfy node install --exit-on-fail comfyui-rmbg --mode remote)
RUN git clone https://github.com/kijai/ComfyUI-KJNodes /comfyui/custom_nodes/ComfyUI-KJNodes && cd /comfyui/custom_nodes/ComfyUI-KJNodes && (git checkout a3250418d58d81aada1826aecaa4ccfce9963def 2>/dev/null || (git fetch origin a3250418d58d81aada1826aecaa4ccfce9963def --depth=1 && git checkout a3250418d58d81aada1826aecaa4ccfce9963def) || echo "WARN: commit a3250418d58d81aada1826aecaa4ccfce9963def unreachable in https://github.com/kijai/ComfyUI-KJNodes, falling back to default branch HEAD")

# copy all input data (like images or videos) into comfyui (uncomment and adjust if needed)
# COPY input/ /comfyui/input/

# user-provided inputs override the auto-generated placeholders above.
RUN wget --progress=dot:giga -O '/comfyui/input/1.jpg' "https://cool-anteater-319.convex.cloud/api/storage/569d11fe-c000-4f62-897b-5ac30f058c2b"
RUN wget --progress=dot:giga -O '/comfyui/input/pasted/image.png' "https://cool-anteater-319.convex.cloud/api/storage/1e17ad82-b0f4-4b0c-8cea-9f56f1ad8a04"
