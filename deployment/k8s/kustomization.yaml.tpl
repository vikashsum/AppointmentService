resources:
  - appointmentservice-deployment.yaml
  - patientservice-deployment.yaml
  - patientportal-deployment.yaml
  - doctorservice-deployment.yaml
  - service-ingress.yaml

images:
  - name: vikash3117/appointmentservice
    newName: vikash3117/appointmentservice
    newTag: ${APPOINTMENT_TAG}
  - name: vikash3117/patientservic
    newName: vikash3117/patientservic
    newTag: ${PATIENT_TAG}
  - name: vikash3117/patient-portal
    newName: vikash3117/patient-portal
    newTag: ${PORTAL_TAG}
  - name: vikash3117/doctorservice
    newName: vikash3117/doctorservice
    newTag: ${DOCTOR_TAG}
