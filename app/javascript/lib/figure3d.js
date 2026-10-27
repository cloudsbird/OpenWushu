// 3D figure for the 图解 illustrations, ported unchanged from the design prototype (design/prototype/Main.dc.html).
// Joints in centimetres: x = athlete's left, y = up, z = forward (towards the judges). yaw turns the whole body (deg, + = left).
// Poses are illustrative: in the real app a contributor poses them in a 3D tool and a coach checks them.
export const JN = ['head', 'neck', 'shL', 'shR', 'elbL', 'elbR', 'hndL', 'hndR', 'pelvis', 'hipL', 'hipR', 'kneeL', 'kneeR', 'ankL', 'ankR', 'toeL', 'toeR'];
// Drawn as a person in a loose 太极 uniform: tapered sleeves and trousers, hands, shoes, jacket with frog buttons, hair.
function f1(n) { return n.toFixed(1); }
function project3(q, a) {
  var e = 10 * Math.PI / 180, x = q[0] * Math.cos(a) + q[2] * Math.sin(a), z = -q[0] * Math.sin(a) + q[2] * Math.cos(a);
  return { x: x, y: q[1] * Math.cos(e) - z * Math.sin(e), z: q[1] * Math.sin(e) + z * Math.cos(e) };
}
// Orthographic camera: az = camera angle around the athlete (deg), slight elevation
function projectPose(pose, az) {
  var a = (pose.yaw + az) * Math.PI / 180, out = { a: a };
  JN.forEach(function (name, k) { out[name] = project3(pose.j[k], a); });
  var n = out.neck, h = out.head;
  out.headBase = { x: n.x + 0.4 * (h.x - n.x), y: n.y + 0.4 * (h.y - n.y), z: n.z + 0.4 * (h.z - n.z) };
  return out;
}
// Tapered capsule between two screen points (radius r1 at A, r2 at B), with rounded ends
function capsule(A, B, r1, r2) {
  var dx = B.x - A.x, dy = B.y - A.y, L = Math.hypot(dx, dy);
  if (L < 0.01) { dx = 0; dy = 1; L = 1; }
  var ux = dx / L, uy = dy / L, nx = -uy, ny = ux, k = 1.33;
  var P = function (x, y) { return f1(x) + ' ' + f1(y); };
  return 'M' + P(A.x + nx * r1, A.y + ny * r1) + ' L' + P(B.x + nx * r2, B.y + ny * r2) +
    ' C' + P(B.x + nx * r2 + ux * r2 * k, B.y + ny * r2 + uy * r2 * k) + ' ' + P(B.x - nx * r2 + ux * r2 * k, B.y - ny * r2 + uy * r2 * k) + ' ' + P(B.x - nx * r2, B.y - ny * r2) +
    ' L' + P(A.x - nx * r1, A.y - ny * r1) +
    ' C' + P(A.x - nx * r1 - ux * r1 * k, A.y - ny * r1 - uy * r1 * k) + ' ' + P(A.x + nx * r1 - ux * r1 * k, A.y + ny * r1 - uy * r1 * k) + ' ' + P(A.x + nx * r1, A.y + ny * r1) + ' Z';
}
function hull(pts) {
  pts = pts.slice().sort(function (p, q) { return p.x - q.x || p.y - q.y; });
  var cross = function (o, a, b) { return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x); }, lo = [], up = [];
  pts.forEach(function (p) { while (lo.length > 1 && cross(lo[lo.length - 2], lo[lo.length - 1], p) <= 0) lo.pop(); lo.push(p); });
  pts.slice().reverse().forEach(function (p) { while (up.length > 1 && cross(up[up.length - 2], up[up.length - 1], p) <= 0) up.pop(); up.push(p); });
  return lo.slice(0, -1).concat(up.slice(0, -1));
}
// Renders a pose as a clothed figure (painter's algorithm, far parts first) plus a motion arrow towards the next pose
export function render3d(pose, az, next) {
  var P = projectPose(pose, az), K = 0.9, a = P.a, J = function (n) { return pose.j[JN.indexOf(n)]; };
  var xs = JN.map(function (n) { return P[n].x; }), cx = (Math.min.apply(null, xs) + Math.max.apply(null, xs)) / 2;
  var S = function (q) { return { x: 60 + (q.x - cx) * K, y: 171 - q.y * K, z: q.z }; }, Q = {};
  JN.concat(['headBase']).forEach(function (n) { Q[n] = S(P[n]); });
  var shapes = [];
  var add = function (d, z) { shapes.push({ d: d, z: z }); };
  var limb = function (A, B, r1, r2, dz) { add(capsule(Q[A], Q[B], r1 * K, r2 * K), (Q[A].z + Q[B].z) / 2 + (dz || 0)); };
  ['L', 'R'].forEach(function (sd) {
    limb('hip' + sd, 'knee' + sd, 9.5, 7.6);          // loose trousers
    limb('knee' + sd, 'ank' + sd, 7.4, 8.8);          // flared trouser leg
    limb('ank' + sd, 'toe' + sd, 3.8, 3.2, 1);        // shoe
    limb('sh' + sd, 'elb' + sd, 6.2, 5.4);            // sleeve
    limb('elb' + sd, 'hnd' + sd, 5.4, 5.0);           // sleeve to the cuff
    var W = Q['hnd' + sd], E = Q['elb' + sd], L = Math.hypot(W.x - E.x, W.y - E.y) || 1;
    var tipPt = { x: W.x + (W.x - E.x) / L * 7 * K, y: W.y + (W.y - E.y) / L * 7 * K, z: W.z };
    add(capsule(W, tipPt, 3.2 * K, 2.6 * K), W.z + 2);  // hand
  });
  limb('neck', 'headBase', 4, 4, -1);
  // jacket: hull of the shoulders and hem, given 3D depth so it stays solid from the side
  var box = [];
  [['shL', -3, 9], ['shR', -3, 9], ['hipL', 8, 11], ['hipR', 8, 11]].forEach(function (c) {
    var q = J(c[0]), hem = c[0].indexOf('hip') === 0 ? -8 : 0;
    [-c[2], c[2]].forEach(function (dz) { box.push(S(project3([q[0] + (q[0] > 0 ? c[1] > 0 ? 6 : 4 : c[1] > 0 ? -6 : -4), q[1] + hem, q[2] + dz], a))); });
  });
  var hp = hull(box), torsoZ = (Q.shL.z + Q.shR.z + Q.hipL.z + Q.hipR.z) / 4;
  add('M' + hp.map(function (q) { return f1(q.x) + ' ' + f1(q.y); }).join(' L') + ' Z', torsoZ);
  shapes.sort(function (u, v) { return u.z - v.z; });
  var r = { gy: 172, arc: '', tip: '', btn: '' };
  shapes.forEach(function (g, i) { r['s' + i] = g.d; });
  // jacket centre line and frog buttons, only when the front faces the viewer
  var facing = Math.cos(a);
  if (facing > 0.35) {
    var ms = J('shL'), mr = J('shR'), hl = J('hipL'), hr = J('hipR');
    var top = S(project3([(ms[0] + mr[0]) / 2, (ms[1] + mr[1]) / 2 - 4, (ms[2] + mr[2]) / 2 + 9], a));
    var bot = S(project3([(hl[0] + hr[0]) / 2, (hl[1] + hr[1]) / 2 - 7, (hl[2] + hr[2]) / 2 + 11], a));
    var bx = bot.x - top.x, by = bot.y - top.y, bl = Math.hypot(bx, by) || 1, px = -by / bl * 3, py = bx / bl * 3;
    r.btn = 'M' + f1(top.x) + ' ' + f1(top.y) + ' L' + f1(bot.x) + ' ' + f1(bot.y);
    [0.15, 0.35, 0.55, 0.75].forEach(function (u) { var mx = top.x + bx * u, my = top.y + by * u; r.btn += ' M' + f1(mx - px) + ' ' + f1(my - py) + ' L' + f1(mx + px) + ' ' + f1(my + py); });
  }
  // head and hair: a cap from the front, the back of the head when facing away
  var H = Q.head, rx = 8.2 * K, ry = 9.6 * K, back = -Math.sin(a) * 3 * K;
  r.hx = f1(H.x); r.hy = f1(H.y); r.hrx = f1(rx); r.hry = f1(ry);
  r.hair = facing < -0.3
    ? 'M' + f1(H.x - rx) + ' ' + f1(H.y) + ' A' + f1(rx) + ' ' + f1(ry) + ' 0 1 0 ' + f1(H.x + rx) + ' ' + f1(H.y) + ' A' + f1(rx) + ' ' + f1(ry) + ' 0 1 0 ' + f1(H.x - rx) + ' ' + f1(H.y) + ' Z'
    : 'M' + f1(H.x - rx) + ' ' + f1(H.y - 1) + ' Q' + f1(H.x + back) + ' ' + f1(H.y - ry * 2.05) + ' ' + f1(H.x + rx) + ' ' + f1(H.y - 1) + ' Q' + f1(H.x + back * 2) + ' ' + f1(H.y - ry * 0.8) + ' ' + f1(H.x - rx) + ' ' + f1(H.y - 1) + ' Z';
  if (next) {
    var N = projectPose(next, az), best = null, sxN = function (q) { return { x: 60 + (q.x - cx) * K, y: 171 - q.y * K }; };
    ['hndL', 'hndR', 'toeL', 'toeR'].forEach(function (k) {
      var A = Q[k], B = sxN(N[k]), dist = Math.hypot(B.x - A.x, B.y - A.y);
      if (!best || dist > best.dist) best = { x1: A.x, y1: A.y, x2: B.x, y2: B.y, dist: dist };
    });
    if (best && best.dist > 6) {
      var mx = (best.x1 + best.x2) / 2, my = (best.y1 + best.y2) / 2, dx = best.x2 - best.x1, dy = best.y2 - best.y1;
      var c = { x: mx - dy * 0.35, y: my + dx * 0.35 }, ux = best.x2 - c.x, uy = best.y2 - c.y, ul = Math.hypot(ux, uy) || 1;
      ux /= ul; uy /= ul;
      r.arc = 'M' + f1(best.x1) + ' ' + f1(best.y1) + ' Q' + f1(c.x) + ' ' + f1(c.y) + ' ' + f1(best.x2) + ' ' + f1(best.y2);
      r.tip = 'M' + f1(best.x2 + ux * 3) + ' ' + f1(best.y2 + uy * 3) + ' L' + f1(best.x2 - ux * 4 - uy * 3) + ' ' + f1(best.y2 - uy * 4 + ux * 3) + ' L' + f1(best.x2 - ux * 4 + uy * 3) + ' ' + f1(best.y2 - uy * 4 - ux * 3) + ' Z';
    }
  }
  return r;
}
