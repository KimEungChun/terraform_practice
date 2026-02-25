pipeline {
  agent any
  stages {
    stage('SSH test') {
      steps {
        sshagent(credentials: ['app-ec2-ssh']) {
          sh '''
            ssh -o StrictHostKeyChecking=no ubuntu@10.20.2.236 "hostname; whoami; uptime"
          '''
        }
      }
    }
  }
stage('App EC2 precheck') {
  steps {
    sshagent(credentials: ['app-ec2-ssh']) {
      sh '''
        ssh -o StrictHostKeyChecking=no ubuntu@10.20.2.236 "
          set -e
          echo '== PATH ==' && echo $PATH
          echo '== node ==' && node -v || true
          echo '== npm ==' && npm -v || true
          echo '== pm2 ==' && pm2 -v || true
          echo '== nginx ==' && nginx -v || true
          echo '== app dir ==' && ls -al /srv || true
        "
      '''
    }
  }
}  
}