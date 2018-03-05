#!/bin/bash 

INVENTORY_FILE="inventory"
PLAYBOOK="artifactory-install-configure.yml"

is_ansible_installed() {
    type -p ansible-playbook > /dev/null
}

log_success() {
    if [ $# -eq 0 ]; then
        cat
    else
        echo "$*"
    fi
}


log_error() {
    echo -n "[error] "
    if [ $# -eq 0 ]; then
        cat
    else
        echo "$*"
    fi
}

distribution_id() {
    RETVAL=""
    if  [ -z "${RETVAL}" -a -e "/etc/lsb-release" ]; then
        RELEASE_OUT=$(head -n1 /etc/lsb-release)
        case "${RELEASE_OUT}" in
             Red\ Hat\ Enterprise\ Linux*)
                RETVAL="rhel"
                ;;
            CentOS*)
                RETVAL="centos"
                ;;
            Fedora*)
                RETVAL="fedora"
                ;;
           DISTRIB_ID=Ubuntu*)
                 RETVAL="Ubuntu"
        esac
       echo $RETVAL
    fi
} 

distribution_id

distribution_major_version() {
    for RELEASE_FILE in /etc/system-release \
                        /etc/centos-release \
                        /etc/fedora-release \
                        /etc/redhat-release \
                        /etc/lsb-release
    do
        if [ -e "${RELEASE_FILE}" ]; then
            RELEASE_VERSION=$(tail -n1 ${RELEASE_FILE})
            break
        fi
    done
    echo ${RELEASE_VERSION} 
}

distribution_major_version

is_ansible_installed
if [ $? -ne 0 ]; then
    SKIP_ANSIBLE_CHECK=0
    case $(distribution_id) in

    rhel|centos|ol|Ubuntu)
            DISTRIBUTION_MAJOR_VERSION=$(distribution_major_version)
            is_bundle_install
            if [ $? -eq 0 ]; then
                log_warning "Will install bundled Ansible"
                    SKIP_ANSIBLE_CHECK=1
            else
                case ${DISTRIBUTION_MAJOR_VERSION} in
                    DISTRIB_DESCRIPTION="Ubuntu 16.04.3 LTS")
                        echo "inside dist description"
                        apt-get update -y
                        apt-add-repository ppa:ansible/ansible -y                
                        ;;
                esac
                apt-get install -y ansible
            fi
    esac
# Check whether ansible was successfully installed
    if [ ${SKIP_ANSIBLE_CHECK} -ne 1 ]; then
        is_ansible_installed
        if [ $? -ne 0 ]; then
            log_error "Unable to install ansible."
            fatal_ansible_not_installed
        fi
    fi
fi

#Run the playbook
ansible-playbook -i "${INVENTORY_FILE}" $PLAYBOOK 2>&1 

# Save the exit code and output accordingly.
RC=$?
if [ ${RC} -ne 0 ]; then
    log_error "Oops!  An error occured while running setup."
else
    log_success "The setup process completed successfully."
fi



