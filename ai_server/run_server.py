import subprocess
from pathlib import Path

root = Path(__file__).resolve().parent.parent
model_path = root / "models" / "Qwen_Qwen3-4B-Instruct-2507-Q4_K_M.gguf"

if not model_path.exists():
    raise FileNotFoundError(
        f"Model not found: {model_path}\n"
        "Run: python ai_server/download_model.py"
    )

cmd = [
    "python",
    "-m",
    "llama_cpp.server",
    "--model",
    str(model_path),
    "--host",
    "127.0.0.1",
    "--port",
    "8000",
    "--n_ctx",
    "8192",
    "--n_gpu_layers",
    "0"
]

print("Starting local AI server...")
print("API: http://127.0.0.1:8000/v1/chat/completions")
subprocess.run(cmd)
