from huggingface_hub import hf_hub_download
from pathlib import Path

repo_id = "bartowski/Qwen_Qwen3-4B-Instruct-2507-GGUF"
filename = "Qwen_Qwen3-4B-Instruct-2507-Q4_K_M.gguf"

out_dir = Path(__file__).resolve().parent.parent / "models"
out_dir.mkdir(parents=True, exist_ok=True)

print("Downloading model...")
path = hf_hub_download(
    repo_id=repo_id,
    filename=filename,
    local_dir=out_dir
)

print("Model downloaded to:", path)
