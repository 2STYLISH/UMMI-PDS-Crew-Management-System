import http from 'k6/http';
import { check, sleep } from 'k6';
import { parseHTML } from 'k6/html';
import { Counter, Trend } from 'k6/metrics';

// --- Custom Metrics Definition ---
export const authFailures = new Counter('auth_failures');
export const unexpected5xx = new Counter('unexpected_5xx');

// Operation durations (Trends)
export const crewSearchDuration = new Trend('op_crew_search_duration', true);
export const applicantPoolDuration = new Trend('op_applicant_pool_duration', true);
export const profileViewerDuration = new Trend('op_profile_viewer_duration', true);
export const vesselCclDuration = new Trend('op_vessel_ccl_duration', true);
export const homeDuration = new Trend('op_home_duration', true);
export const activityLogsDuration = new Trend('op_activity_logs_duration', true);

// Operation counts
export const crewSearchCount = new Counter('op_crew_search_count');
export const applicantPoolCount = new Counter('op_applicant_pool_count');
export const profileViewerCount = new Counter('op_profile_viewer_count');
export const vesselCclCount = new Counter('op_vessel_ccl_count');
export const homeCount = new Counter('op_home_count');
export const activityLogsCount = new Counter('op_activity_logs_count');

// HTTP Status Counters
export const status2xx = new Counter('status_2xx');
export const status3xx = new Counter('status_3xx');
export const status4xx = new Counter('status_4xx');
export const status5xx = new Counter('status_5xx');

// Stage selection via environment variable
const STAGE = __ENV.LOAD_STAGE || '1';

function getStageConfig() {
  switch (STAGE) {
    case '1':
      return [
        { duration: '1m', target: 1 }, // Stage 1: 1 user for 1 minute
      ];
    case '2':
      return [
        { duration: '30s', target: 5 }, // Stage 2: Ramp to 5 users over 30s
        { duration: '2m', target: 5 },  // Hold 5 users for 2m
        { duration: '30s', target: 0 }, // Ramp down over 30s
      ];
    case '3':
      return [
        { duration: '1m', target: 20 }, // Stage 3: Ramp to 20 users over 1m
        { duration: '3m', target: 20 }, // Hold 20 users for 3m
        { duration: '1m', target: 0 },  // Ramp down over 1m
      ];
    case '4':
      return [
        { duration: '1m', target: 25 },  // Stage 4: Ramp to 25 users over 1m
        { duration: '1m', target: 50 },  // Ramp to 50 users over 1m
        { duration: '1m', target: 75 },  // Ramp to 75 users over 1m
        { duration: '2m', target: 100 }, // Ramp to 100 users over 2m
        { duration: '10m', target: 100 }, // Hold 100 users for 10m (Sustained)
        { duration: '2m', target: 0 },   // Ramp down over 2m
      ];
    case 'SMOKE':
      return [
        { duration: '15s', target: 1 },
      ];
    default:
      return [
        { duration: '1m', target: 1 },
      ];
  }
}

export const options = {
  stages: getStageConfig(),
  thresholds: {
    // Acceptance criteria
    http_req_failed: [{ threshold: 'rate<0.01', abortOnFail: false }],
    checks: [{ threshold: 'rate>=0.99', abortOnFail: false }],
    'http_req_duration{expected_response:true}': [
      { threshold: 'p(95)<=3000', abortOnFail: false },
      { threshold: 'p(99)<=5000', abortOnFail: false },
    ],
    unexpected_5xx: [{ threshold: 'count==0', abortOnFail: false }],
    auth_failures: [{ threshold: 'count==0', abortOnFail: false }],
  },
  userAgent: 'k6-load-tester/tc-cm-182',
};

const BASE_URL = __ENV.TARGET_URL || 'https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net';
const USERNAME = __ENV.LOAD_TEST_USER;
const PASSWORD = __ENV.LOAD_TEST_PASS;

// Per-VU state
let vuIsLoggedIn = false;
let knownProfileUrls = [];

function extractHiddenFields(doc) {
  return {
    viewState: doc.find('input[name="__VIEWSTATE"]').attr('value') || '',
    viewStateGen: doc.find('input[name="__VIEWSTATEGENERATOR"]').attr('value') || '',
    eventValidation: doc.find('input[name="__EVENTVALIDATION"]').attr('value') || '',
  };
}

function recordResponseMetrics(res) {
  if (res.status >= 200 && res.status < 300) {
    status2xx.add(1);
  } else if (res.status >= 300 && res.status < 400) {
    status3xx.add(1);
  } else if (res.status >= 400 && res.status < 500) {
    status4xx.add(1);
  } else if (res.status >= 500) {
    status5xx.add(1);
    unexpected5xx.add(1);
  }
}

function login() {
  const getRes = http.get(`${BASE_URL}/login.aspx`, { tags: { name: 'GET_Login' } });
  recordResponseMetrics(getRes);

  const getPass = check(getRes, {
    'GET /login.aspx returns 200': (r) => r.status === 200,
  });
  if (!getPass) {
    authFailures.add(1);
    return false;
  }

  const doc = parseHTML(getRes.body);
  const hidden = extractHiddenFields(doc);

  const postRes = http.post(`${BASE_URL}/login.aspx`, {
    __VIEWSTATE: hidden.viewState,
    __VIEWSTATEGENERATOR: hidden.viewStateGen,
    __EVENTVALIDATION: hidden.eventValidation,
    txtUsername: USERNAME,
    txtPassword: PASSWORD,
    btnLogin: 'Sign In',
  }, {
    redirects: 5,
    tags: { name: 'POST_Login' },
  });
  recordResponseMetrics(postRes);

  const isAuthSuccess = postRes.status === 200 &&
    !postRes.body.includes('Invalid username or password') &&
    (postRes.body.includes('Home') || postRes.body.includes('Dashboard') || postRes.body.includes('Sign out') || postRes.body.includes('QueryCrew'));

  const loginPass = check(postRes, {
    'POST /login.aspx succeeds with 200': (r) => r.status === 200,
    'Session established without auth error': () => isAuthSuccess,
  });

  if (!loginPass || !isAuthSuccess) {
    authFailures.add(1);
    return false;
  }

  vuIsLoggedIn = true;
  return true;
}

function executeCrewSearch() {
  crewSearchCount.add(1);
  const start = Date.now();

  const isFilter = Math.random() < 0.5;

  if (!isFilter) {
    // GET initial Crew Search page
    const res = http.get(`${BASE_URL}/Crew/QueryCrew.aspx`, { tags: { name: 'GET_CrewSearch' } });
    recordResponseMetrics(res);

    check(res, {
      'Crew Search initial page status is 200': (r) => r.status === 200,
      'Crew Search rendered form': (r) => r.body.includes('QueryCrew') || r.body.includes('Crew Search'),
    });

    // Harvest profile URLs
    if (res.status === 200) {
      const doc = parseHTML(res.body);
      const links = doc.find('a[href*="ProfileViewer.aspx"]').toArray();
      for (let l of links) {
        let href = l.attr('href');
        if (href && !knownProfileUrls.includes(href)) {
          knownProfileUrls.push(href);
        }
      }
    }
  } else {
    // Filtered Crew Search via postback
    const getRes = http.get(`${BASE_URL}/Crew/QueryCrew.aspx`, { tags: { name: 'GET_CrewSearch_PreFilter' } });
    recordResponseMetrics(getRes);

    if (getRes.status === 200) {
      const doc = parseHTML(getRes.body);
      const hidden = extractHiddenFields(doc);

      const statuses = ['1', '2', ''];
      const chosenStatus = statuses[Math.floor(Math.random() * statuses.length)];

      const postRes = http.post(`${BASE_URL}/Crew/QueryCrew.aspx`, {
        __VIEWSTATE: hidden.viewState,
        __VIEWSTATEGENERATOR: hidden.viewStateGen,
        __EVENTVALIDATION: hidden.eventValidation,
        ctl00$MainContent$txtLastName: '',
        ctl00$MainContent$txtFirstName: '',
        ctl00$MainContent$drpdwnCrewStatus: chosenStatus,
        ctl00$MainContent$drpdwnCrewAvailability: '',
        ctl00$MainContent$drpdwnRankType: '',
        ctl00$MainContent$drpdwnRank: '0',
        ctl00$MainContent$drpdwnProvince: '',
        ctl00$MainContent$drpdwnCity: '',
        ctl00$MainContent$drpdwnVesselTypeExperience: '',
        ctl00$MainContent$drpdwnVessel: '',
        ctl00$MainContent$txtAge: '',
        ctl00$MainContent$btnSearch: 'Search',
      }, {
        redirects: 5,
        tags: { name: 'POST_CrewSearch_Filter' },
      });
      recordResponseMetrics(postRes);

      check(postRes, {
        'Crew Search filter status is 200': (r) => r.status === 200,
        'Crew Search filter returned grid': (r) => r.body.includes('GridViewQueryCrew') || r.body.includes('tbl_crew') || r.body.includes('No crew found') || r.body.includes('QueryCrew'),
      });

      if (postRes.status === 200) {
        const postDoc = parseHTML(postRes.body);
        const links = postDoc.find('a[href*="ProfileViewer.aspx"]').toArray();
        for (let l of links) {
          let href = l.attr('href');
          if (href && !knownProfileUrls.includes(href)) {
            knownProfileUrls.push(href);
          }
        }
      }
    }
  }

  crewSearchDuration.add(Date.now() - start);
}

function executeApplicantPool() {
  applicantPoolCount.add(1);
  const start = Date.now();

  const isFilter = Math.random() < 0.5;

  if (!isFilter) {
    const res = http.get(`${BASE_URL}/Applicant/ApplicantPool.aspx`, { tags: { name: 'GET_ApplicantPool' } });
    recordResponseMetrics(res);

    check(res, {
      'Applicant Pool initial status is 200': (r) => r.status === 200,
      'Applicant Pool page loaded': (r) => r.body.includes('ApplicantPool') || r.body.includes('Applicant Pool'),
    });
  } else {
    const getRes = http.get(`${BASE_URL}/Applicant/ApplicantPool.aspx`, { tags: { name: 'GET_ApplicantPool_PreFilter' } });
    recordResponseMetrics(getRes);

    if (getRes.status === 200) {
      const doc = parseHTML(getRes.body);
      const hidden = extractHiddenFields(doc);

      const postRes = http.post(`${BASE_URL}/Applicant/ApplicantPool.aspx`, {
        __VIEWSTATE: hidden.viewState,
        __VIEWSTATEGENERATOR: hidden.viewStateGen,
        __EVENTVALIDATION: hidden.eventValidation,
        ctl00$MainContent$txtLastName: '',
        ctl00$MainContent$txtFirstName: '',
        ctl00$MainContent$drpdwnRankType: '',
        ctl00$MainContent$drpdwnRank: '',
        ctl00$MainContent$btnSearch: 'Search',
      }, {
        redirects: 5,
        tags: { name: 'POST_ApplicantPool_Filter' },
      });
      recordResponseMetrics(postRes);

      check(postRes, {
        'Applicant Pool filter status is 200': (r) => r.status === 200,
        'Applicant Pool filter returned table': (r) => r.body.includes('gvApplicants') || r.body.includes('ApplicantPool') || r.body.includes('No applicant'),
      });
    }
  }

  applicantPoolDuration.add(Date.now() - start);
}

function executeProfileViewer() {
  profileViewerCount.add(1);
  const start = Date.now();

  let targetUrl = `${BASE_URL}/Crew/QueryCrew.aspx`;
  if (knownProfileUrls.length > 0) {
    const chosenHref = knownProfileUrls[Math.floor(Math.random() * knownProfileUrls.length)];
    if (chosenHref.startsWith('http')) {
      targetUrl = chosenHref;
    } else if (chosenHref.includes('/Crew/')) {
      targetUrl = `${BASE_URL}/Crew/${chosenHref.replace(/^~\/?Crew\//, '').replace(/^\.\//, '')}`;
    } else {
      targetUrl = `${BASE_URL}/Crew/${chosenHref.replace(/^~\/?/, '')}`;
    }
  }

  const res = http.get(targetUrl, { tags: { name: 'GET_ProfileViewer' } });
  recordResponseMetrics(res);

  check(res, {
    'Profile Viewer status is 200': (r) => r.status === 200,
    'Profile Viewer loaded': (r) => r.body.includes('ProfileViewer') || r.body.includes('Crew Profile') || r.body.includes('QueryCrew'),
  });

  profileViewerDuration.add(Date.now() - start);
}

function executeVesselCcl() {
  vesselCclCount.add(1);
  const start = Date.now();

  const isCcl = Math.random() < 0.5;
  const url = isCcl ? `${BASE_URL}/Crew/CrewChangeList.aspx` : `${BASE_URL}/Crew/VesselCrew.aspx`;
  const tag = isCcl ? 'GET_CrewChangeList' : 'GET_VesselCrew';

  const res = http.get(url, { tags: { name: tag } });
  recordResponseMetrics(res);

  check(res, {
    'Vessel/CCL view status is 200': (r) => r.status === 200,
    'Vessel/CCL page rendered': (r) => r.body.includes('Change Crew List') || r.body.includes('CrewChangeList') || r.body.includes('Vessel Crew') || r.body.includes('VesselCrew') || r.body.includes('GridView'),
  });

  vesselCclDuration.add(Date.now() - start);
}

function executeHome() {
  homeCount.add(1);
  const start = Date.now();

  const res = http.get(`${BASE_URL}/Home.aspx`, { tags: { name: 'GET_Home' } });
  recordResponseMetrics(res);

  check(res, {
    'Home page status is 200': (r) => r.status === 200,
    'Home page loaded dashboard': (r) => r.body.includes('Dashboard') || r.body.includes('Home') || r.body.includes('UMMI'),
  });

  homeDuration.add(Date.now() - start);
}

function executeActivityLogs() {
  activityLogsCount.add(1);
  const start = Date.now();

  const isFilter = Math.random() < 0.5;

  if (!isFilter) {
    const res = http.get(`${BASE_URL}/Settings/ActivityLogs.aspx`, { tags: { name: 'GET_ActivityLogs' } });
    recordResponseMetrics(res);

    check(res, {
      'Activity Logs initial status is 200': (r) => r.status === 200,
      'Activity Logs loaded': (r) => r.body.toLowerCase().includes('activity') || r.body.includes('gvLogs'),
    });
  } else {
    const getRes = http.get(`${BASE_URL}/Settings/ActivityLogs.aspx`, { tags: { name: 'GET_ActivityLogs_PreFilter' } });
    recordResponseMetrics(getRes);

    if (getRes.status === 200) {
      const doc = parseHTML(getRes.body);
      const hidden = extractHiddenFields(doc);

      const postRes = http.post(`${BASE_URL}/Settings/ActivityLogs.aspx`, {
        __VIEWSTATE: hidden.viewState,
        __VIEWSTATEGENERATOR: hidden.viewStateGen,
        __EVENTVALIDATION: hidden.eventValidation,
        ctl00$MainContent$drpdwnCategory: 'Login',
        ctl00$MainContent$btnSearch: 'Search',
      }, {
        redirects: 5,
        tags: { name: 'POST_ActivityLogs_Filter' },
      });
      recordResponseMetrics(postRes);

      check(postRes, {
        'Activity Logs filter status is 200': (r) => r.status === 200,
        'Activity Logs filter grid loaded': (r) => r.body.toLowerCase().includes('activity') || r.body.includes('gvLogs'),
      });
    }
  }

  activityLogsDuration.add(Date.now() - start);
}

export default function () {
  // Ensure VU is logged in
  if (!vuIsLoggedIn) {
    const ok = login();
    if (!ok) {
      sleep(2);
      return;
    }
    sleep(1);
  }

  // Weighted operation selection:
  // - Crew Search and filtering: 30% [0 - 30)
  // - Applicant Pool and filtering: 20% [30 - 50)
  // - Crew Profile viewing: 20% [50 - 70)
  // - Vessel Crew or CCL roster viewing: 15% [70 - 85)
  // - Home/dashboard navigation: 10% [85 - 95)
  // - Activity Logs viewing: 5% [95 - 100)
  const roll = Math.random() * 100;

  try {
    if (roll < 30) {
      executeCrewSearch();
    } else if (roll < 50) {
      executeApplicantPool();
    } else if (roll < 70) {
      executeProfileViewer();
    } else if (roll < 85) {
      executeVesselCcl();
    } else if (roll < 95) {
      executeHome();
    } else {
      executeActivityLogs();
    }
  } catch (err) {
    // Catch unexpected script errors to avoid VU abort
  }

  // Realistic user think time between actions: 1.0 - 2.5 seconds
  sleep(Math.random() * 1.5 + 1.0);
}

export function handleSummary(data) {
  const stageName = __ENV.LOAD_STAGE || '1';
  const out = {};
  out[`qa/playwright/test-results/tc182-load-test/stage${stageName}-results.json`] = JSON.stringify(data, null, 2);
  if (stageName === '4' || stageName === 'ALL') {
    out['qa/playwright/evidence/tc182-load-test-results.json'] = JSON.stringify(data, null, 2);
  }
  return out;
}
