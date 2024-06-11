temporary_image_id := "0.x.x-dev-cargo-near"
temporary_image_id_latest := temporary_image_id + ":latest"
remote_image_repo := "dj8yfo/sourcescan"
remote_image_id := remote_image_repo + ":0.x.x-dev-cargo-near-finalization"

# cleanup in symlinked dir
cleanup:
    rm -rf cargo-near
    cp -rHv cargo-near1 cargo-near
    pushd cargo-near && cargo clean && popd

# build dockerfile from symlinked `cargo-near`
build_image: cleanup
    docker build -t {{temporary_image_id}} .

push_image_to_remote:
    docker tag {{temporary_image_id_latest}} {{remote_image_id}}
    docker push {{remote_image_id}}

print_latest_image:
    docker image ls --digests  | grep {{remote_image_repo}} | grep {{temporary_image_id}} | head -n 1 | awk '{print $3}'
