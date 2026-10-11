import subprocess
import json
import sys

def main():
    print("Running dart analyze...")
    result = subprocess.run(
        r"C:\src\flutter\bin\dart.bat analyze --format=json lib",
        capture_output=True,
        text=True,
        shell=True,
        stdin=subprocess.DEVNULL,
        cwd=r"e:\kurichiyar matrimony"
    )
    stdout = result.stdout
    stderr = result.stderr
    print(f"Finished with exit code {result.returncode}")
    if stderr:
        print("STDERR:", stderr)
    if stdout:
        print("STDOUT:", stdout[:500])
    
    try:
        data = json.loads(stdout)
        diagnostics = data.get("diagnostics", [])
        errors = [d for d in diagnostics if d.get("severity") == "ERROR"]
        warnings = [d for d in diagnostics if d.get("severity") == "WARNING"]
        infos = [d for d in diagnostics if d.get("severity") == "INFO"]
        
        print(f"\nTOTAL PROBLEMS: {len(diagnostics)}")
        print(f"  ERRORS:   {len(errors)}")
        print(f"  WARNINGS: {len(warnings)}")
        print(f"  INFOS:    {len(infos)}")
        
        if errors:
            print(f"\n--- CRITICAL ERRORS ({len(errors)}) ---")
            for e in errors:
                loc = e.get("location", {})
                print(f"[{loc.get('file')}:{loc.get('range', {}).get('start', {}).get('line')}] {e.get('code')}: {e.get('problemMessage')}")
                
        if warnings:
            print(f"\n--- WARNINGS ({len(warnings)}) ---")
            for w in warnings[:20]:
                loc = w.get("location", {})
                print(f"[{loc.get('file')}:{loc.get('range', {}).get('start', {}).get('line')}] {w.get('code')}: {w.get('problemMessage')}")

        with open(r"e:\kurichiyar matrimony\analysis_summary.json", "w", encoding="utf-8") as f:
            json.dump({
                "error_count": len(errors),
                "warning_count": len(warnings),
                "info_count": len(infos),
                "errors": errors,
                "warnings": warnings,
            }, f, indent=2)
    except Exception as ex:
        print("JSON parse failed:", ex)


if __name__ == "__main__":
    main()
