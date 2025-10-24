!/bin/sh

# === Auto-generate OSS config file ===
mkdir -p /root
cat > /root/.ossutilconfig <<EOF
[Credentials]
language=EN
endpoint=${OSS_ENDPOINT:-oss-ap-southeast-1.aliyuncs.com}
accessKeyID=${OSS_ACCESS_KEY_ID}
accessKeySecret=${OSS_ACCESS_KEY_SECRET}
EOF

ROOT="oss://s3-slice/screenshots/"
TARGET_ROOT="oss://s3-slice/compressed"

echo "[INIT] OSS util configured. Using endpoint: ${OSS_ENDPOINT:-oss-ap-southeast-1.aliyuncs.com}"

while true; do
  echo "[INFO] Scanning for all image folders under $ROOT"

  # Discover unique image prefixes (folders with /images/)
  BUCKETS=$(ossutil64 ls "$ROOT" --recursive \
    | grep "/images/" \
    | awk '{print $NF}' \
    | sed -E 's|(.*images/).*|\1|' \
    | sort -u)

  for BUCKET in $BUCKETS; do
    echo "[INFO] Processing bucket path: $BUCKET"

    latest_file=$(ossutil64 ls "$BUCKET" \
      | grep ".png" \
      | awk '{print $NF}' \
      | sort \
      | tail -n 1)

    if [ -z "$latest_file" ]; then
      echo "[WARN] No PNG files found in $BUCKET"
      continue
    fi

    echo "[INFO] Latest file is: $latest_file"

    # === Download latest PNG ===
    ossutil64 cp "$latest_file" /tmp/latest.png --force
    if [ ! -f /tmp/latest.png ]; then
      echo "[WARN] Failed to download $latest_file, skipping..."
      continue
    fi

    # === Resize and convert to WebP ===
    convert /tmp/latest.png -resize 30% /tmp/resized.png

    filename=$(basename "$latest_file")
    prefix=$(echo "$filename" | sed -E 's/.*((F)[0-9]+_MAIN).*/\1/')
    OUTPUT_WEBP="/tmp/${prefix}.webp"

    cwebp -q 30 /tmp/resized.png -o "$OUTPUT_WEBP"

    # === Upload WebP and backup to top-level ===
    echo "[INFO] Uploading ${prefix}.webp ..."
    ossutil64 cp "$OUTPUT_WEBP" "${TARGET_ROOT}${prefix}/${prefix}.webp" --force
    ossutil64 cp "$OUTPUT_WEBP" "${TARGET_ROOT}${prefix}/${prefix}_backup.webp" --force

    # === Delete old PNGs except the latest ===
    ossutil64 ls "$BUCKET" | grep ".png" | awk '{print $NF}' | grep -v "$(basename "$latest_file")" | while read -r oldfile; do
      echo "[INFO] Deleting old file: $oldfile"
      ossutil64 rm "$oldfile" -f
    done

    echo "[DONE] Finished processing $latest_file"
  done

  echo "[INFO] Sleeping 15s..."
  sleep 15
done
