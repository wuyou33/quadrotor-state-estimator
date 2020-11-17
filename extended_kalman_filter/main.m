format long g
csv = csvread("gps_imu_compass_barometer_log1.csv");

%ms
timestamp_ms = csv(:, 1);
%m/s^2
accel_lpf_x = csv(:, 2);
accel_lpf_y = csv(:, 3);
accel_lpf_z = csv(:, 4);
%rad/s
gyro_raw_x = csv(:, 5);
gyro_raw_y = csv(:, 6);
gyro_raw_z = csv(:, 7);
%uT
mag_raw_x = csv(:, 8);
mag_raw_y = csv(:, 9);
mag_raw_z = csv(:, 10);
%degree
longitude = csv(:, 11);
latitude = csv(:, 12);
%m
gps_height_msl = csv(:, 13);
%m/s
gps_ned_vx = csv(:, 14);
gps_ned_vy = csv(:, 15);
gps_ned_vz = csv(:, 16);
%m
barometer_height = csv(:, 17);
%m/s
barometer_vz = csv(:, 18);

timestamp_s = timestamp_ms .* 0.001;
[data_num, dummy] = size(timestamp_ms);

%fusion period
dt = 0.01; %100Hz, 0.01s

ekf = ekf_estimator;

%set home position
home_longitude = 120.9971619;
home_latitude = 24.7861614;
inclination_angle = -23.5;
ekf = ekf.set_inclination_angle(inclination_angle);
ekf = ekf.set_home_longitude_latitude(home_longitude, home_latitude, 0);

%record datas
roll = zeros(1, data_num);
pitch = zeros(1, data_num);
yaw = zeros(1, data_num);
%
gps_enu_x = zeros(1, data_num);
gps_enu_y = zeros(1, data_num);
gps_enu_z = zeros(1, data_num);
%
fused_enu_x = zeros(1, data_num);
fused_enu_y = zeros(1, data_num);
fused_enu_z = zeros(1, data_num);
%
fused_enu_vx = zeros(1, data_num);
fused_enu_vy = zeros(1, data_num);
fused_eny_vz = zeros(1, data_num);
%
%visualization of b1, b2, b3 vectors with quiver3
b1_visual_sample_cnt = 500;
quiver_cnt = floor(data_num / b1_visual_sample_cnt);
quiver_orig_x = zeros(1, quiver_cnt);
quiver_orig_y = zeros(1, quiver_cnt);
quiver_orig_z = zeros(1, quiver_cnt);
quiver_b1_u = zeros(1, quiver_cnt);
quiver_b1_v = zeros(1, quiver_cnt);
quiver_b1_w = zeros(1, quiver_cnt);
quiver_b2_u = zeros(1, quiver_cnt);
quiver_b2_v = zeros(1, quiver_cnt);
quiver_b2_w = zeros(1, quiver_cnt);
quiver_b3_u = zeros(1, quiver_cnt);
quiver_b3_v = zeros(1, quiver_cnt);
quiver_b3_w = zeros(1, quiver_cnt);
j = 1;
%corrected gravity vector
gravity_x_arr = zeros(1, data_num);
gravity_y_arr = zeros(1, data_num);
gravity_z_arr = zeros(1, data_num);
gravity_x_arr(1) = accel_lpf_x(1);
gravity_y_arr(1) = accel_lpf_y(2);
gravity_z_arr(1) = -accel_lpf_z(3);
%accelerometer norm and corrected norm
accelerometer_norm_arr = zeros(1, data_num);
gravity_norm_arr = zeros(1, data_num);

vel_ned_body = [0; 0; 0];
                        
for i = 2: data_num
    dt = timestamp_s(i) - timestamp_s(i - 1);
    
    gravity = [-accel_lpf_x(i);
               -accel_lpf_y(i);
               -accel_lpf_z(i)];
    
    gravity_x_arr(i) = gravity(1);
    gravity_y_arr(i) = gravity(2);
    gravity_z_arr(i) = gravity(3);
    
    ekf = ...
        ekf.predict(gyro_raw_x(i), gyro_raw_y(i), gyro_raw_z(i), dt);
    
    ekf = ...
        ekf.accel_correct(gravity(1), gravity(2), gravity(3));
    
    ekf = ...
        ekf.mag_correct(mag_raw_x(i), mag_raw_y(i), mag_raw_z(i));
    
    %gps, barometer raw signal and transform it into enu frame for
    %visualization
    position_enu = ekf.convert_gps_ellipsoid_coordinates_to_enu(longitude(i), latitude(i), barometer_height(i));
    gps_enu_x(i) = position_enu(1);
    gps_enu_y(i) = position_enu(2);
    gps_enu_z(i) = position_enu(3);
    
    q = ekf.get_quaternion();
    euler_angles = ekf.quat_to_euler(q);
    roll(i) = euler_angles(1);
    pitch(i) = euler_angles(2);
    yaw(i) = euler_angles(3);
end

%%%%%%%%
% Plot %
%%%%%%%%

%accelerometer
figure('Name', 'accelerometer');
subplot (3, 1, 1);
plot(timestamp_s, accel_lpf_x);
title('accelerometer');
xlabel('time [s]');
ylabel('ax [m/s^2]');
subplot (3, 1, 2);
plot(timestamp_s, accel_lpf_y);
xlabel('time [s]');
ylabel('ay [m/s^2]');
subplot (3, 1, 3);
plot(timestamp_s, accel_lpf_z);
xlabel('time [s]');
ylabel('az [m/s^2]');

%gyroscope
figure('Name', 'gyroscope');
subplot (3, 1, 1);
plot(timestamp_s, rad2deg(gyro_raw_x));
title('gyroscope');
xlabel('time [s]');
ylabel('wx [rad/s]');
subplot (3, 1, 2);
plot(timestamp_s, rad2deg(gyro_raw_y));
xlabel('time [s]');
ylabel('wy [rad/s]');
subplot (3, 1, 3);
plot(timestamp_s, rad2deg(gyro_raw_z));
xlabel('time [s]');
ylabel('wz [rad/s]');

%magnatometer
figure('Name', 'magnetometer');
subplot (3, 1, 1);
plot(timestamp_s, mag_raw_x);
title('magnetometer');
xlabel('time [s]');
ylabel('mx [uT]');
subplot (3, 1, 2);
plot(timestamp_s, mag_raw_z);
xlabel('time [s]');
ylabel('my [uT]');
subplot (3, 1, 3);
plot(timestamp_s, mag_raw_z);
xlabel('time [s]');
ylabel('mx [uT]');

%estimated roll, pitch and yaw angle
figure('Name', 'euler angles');
subplot (3, 1, 1);
plot(timestamp_s, roll);
title('euler angles');
xlabel('time [s]');
ylabel('roll [deg]');
subplot (3, 1, 2);
plot(timestamp_s, pitch);
xlabel('time [s]');
ylabel('pitch [deg]');
subplot (3, 1, 3);
plot(timestamp_s, yaw);
xlabel('time [s]');
ylabel('yaw [deg]');

%2d position trajectory plot of x-y plane
figure('Name', 'x-y position (enu frame)');
grid on;
hold on;
plot(gps_enu_x, gps_enu_y, ...
     'Color', 'k', ...
     'Marker', 'o', ...
     'LineStyle', 'None', ...
     'MarkerSize', 3);
%plot(fused_enu_x, fused_enu_y, 'Color', 'r');
%legend('gps trajectory', 'fused trajectory') ;
legend('gps trajectory');
title('position (enu frame)');
xlabel('x [m]');
ylabel('y [m]');

%3d visualization of position trajectory
figure('Name', 'x-y-z position (enu frame)');
hold on;
axis equal;
plot3(gps_enu_x, gps_enu_y, barometer_height, ...
      'Color', 'k', ...
      'Marker', 'o', ...
      'LineStyle', 'None', ...
      'MarkerSize', 2);
%plot3(fused_enu_x, fused_enu_y, fused_enu_z, 'Color', 'm');
%quiver3(quiver_orig_x,  quiver_orig_y,  quiver_orig_z, ...
%        quiver_b1_u,  quiver_b1_v,  quiver_b1_w, 'Color', 'r', 'AutoScaleFactor', 0.2);
%quiver3(quiver_orig_x,  quiver_orig_y,  quiver_orig_z, ...
%        quiver_b2_u,  quiver_b2_v,  quiver_b2_w, 'Color', 'g', 'AutoScaleFactor', 0.2);
%quiver3(quiver_orig_x,  quiver_orig_y,  quiver_orig_z, ...
%        quiver_b3_u,  quiver_b3_v,  quiver_b3_w, 'Color', 'b', 'AutoScaleFactor', 0.2);
legend('gps trajectory');
%legend('gps trajectory', 'b1 vector', 'b2 vector', 'b3 vector') 
%legend('gps trajectory', 'fused trajectory', 'b1 vector', 'b2 vector', 'b3 vector') 
title('position (enu frame)');
xlabel('x [m]');
ylabel('y [m]');
zlabel('z [m]');
daspect([1 1 1])
grid on
view(-10,20);


disp("Press any key to leave");
pause;
close all;