import os
import shutil
import stat

def log(msg):
    with open("cleanup_log.txt", "a") as f:
        f.write(msg + "\n")
    print(msg)

def remove_readonly(func, path, excinfo):
    os.chmod(path, stat.S_IWRITE)
    func(path)

def cleanup():
    base_path = r"c:\4th Year 1st Semester\Thesis 1\echoshedv2"
    log(f"Starting cleanup in {base_path}")
    
    items_to_delete = [
        os.path.join(base_path, "lib", "core", "services", "auth_service_supabase.dart"),
        os.path.join(base_path, "lib", "core", "services", "pickup_service_supabase.dart"),
        os.path.join(base_path, "lib", "core", "services", "reminder_service_supabase.dart"),
        os.path.join(base_path, "lib", "core", "services", "special_collection_service_supabase.dart"),
        os.path.join(base_path, "lib", "main_supabase.dart"),
        os.path.join(base_path, "lib.zip"),
        os.path.join(base_path, "waste_segregation.v1i.yolov11.zip"),
        os.path.join(base_path, "waste_segregation.v1i.yolov11"),
        os.path.join(base_path, "PERMISSION_FIX.md"),
        os.path.join(base_path, "FIXED_SCHEDULE_SETUP.md"),
    ]

    for item in items_to_delete:
        if not os.path.exists(item):
            log(f"Skipping: {item} (not found)")
            continue
            
        try:
            if os.path.isdir(item):
                log(f"Deleting directory: {item}")
                shutil.rmtree(item, onerror=remove_readonly)
                log(f"Successfully deleted directory: {item}")
            else:
                log(f"Deleting file: {item}")
                os.chmod(item, stat.S_IWRITE)
                os.remove(item)
                log(f"Successfully deleted file: {item}")
        except Exception as e:
            log(f"Failed to delete {item}: {e}")
    
    log("Cleanup finished")

if __name__ == "__main__":
    if os.path.exists("cleanup_log.txt"):
        os.remove("cleanup_log.txt")
    cleanup()
