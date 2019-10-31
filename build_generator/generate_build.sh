#!/bin/bash -el

empty_script() {
    cat <<EOF
#!/bin/bash -el
EOF
}

generate_file() {
    FILE_NAME=$1

    if [[ ! -f $FILE_NAME ]]; then
        cat > $FILE_NAME
    fi
}

generate_docker_based_tool() {
    DOCKER_IMAGE_NAME="${1:-sample}"

    mkdir -p build_scripts/docker_images/$DOCKER_IMAGE_NAME
    generate_file build_scripts/docker_images/$DOCKER_IMAGE_NAME/build.sh <<EOF
#!/bin/bash -el

docker build -t $DOCKER_IMAGE_NAME .
EOF
    generate_file build_scripts/docker_images/$DOCKER_IMAGE_NAME/test.sh <<EOF
#!/bin/bash -el

docker run -it $DOCKER_IMAGE_NAME /bin/sh
EOF
    echo "FROM" | generate_file build_scripts/docker_images/$DOCKER_IMAGE_NAME/Dockerfile

    mkdir -p build_scripts/tools
    generate_file build_scripts/tools/$DOCKER_IMAGE_NAME <<EOF
#!/bin/bash -el

pushd ./build_scripts/docker_images/$DOCKER_IMAGE_NAME
    ./build.sh
popd

docker run -t                               \\
    -u "\${UID}"                             \\
    -v \$(pwd):/target                       \\
    -w /target                              \\
    $DOCKER_IMAGE_NAME $DOCKER_IMAGE_NAME \$*
EOF
}


mkdir -p build_scripts
empty_script | generate_file build_scripts/build.sh

generate_docker_based_tool sample1

chmod +x ./build_scripts/*.sh
chmod +x ./build_scripts/docker_images/*/*.sh
chmod +x ./build_scripts/tools/*
