"""Build-time CPU check of node registration and enum compatibility, not GPU inference."""
import json
import subprocess
import time
import urllib.request

workflow = json.load(open('/adnoc/api-workflow.json'))
process = subprocess.Popen(['/opt/venv/bin/python', 'main.py', '--cpu', '--listen', '127.0.0.1', '--port', '8188'], cwd='/comfyui')
try:
    deadline = time.monotonic() + 240
    while True:
        if process.poll() is not None:
            raise RuntimeError('ComfyUI exited before its node API became ready')
        try:
            with urllib.request.urlopen('http://127.0.0.1:8188/object_info', timeout=5) as response:
                info = json.load(response)
            break
        except (OSError, ValueError):
            if time.monotonic() > deadline:
                raise RuntimeError('ComfyUI startup timed out')
            time.sleep(2)
    for node in workflow.values():
        kind = node['class_type']
        assert kind in info, f'Missing node: {kind}'
        schema = info[kind]['input']
        fields = {**schema.get('required', {}), **schema.get('optional', {})}
        for name, value in node['inputs'].items():
            if isinstance(value, list):
                continue  # Connected input, not an enum literal.
            definition = fields.get(name)
            if definition and isinstance(definition[0], list) and kind != 'LoadImage':
                assert value in definition[0], f'{kind}.{name}: unsupported {value!r}'
    print('ADNOC node registrations and enum values verified')
finally:
    process.terminate()
    try:
        process.wait(timeout=15)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
