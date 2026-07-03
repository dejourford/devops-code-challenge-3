import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
  vus: 300,
  duration: '2m',
};

export default function () {
  http.get('http://k8s-default-appingre-0e6efb69ca-655013439.us-east-2.elb.amazonaws.com/api');
  sleep(1);
}
