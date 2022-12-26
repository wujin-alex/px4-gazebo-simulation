# PX4-Gazebo-Simulation

## 环境配置
### 安装mavlink
```shell
$ sudo apt-get install ros-foxy-mavlink
```

## 编译

```shell
$ mkdir build && cd build
$ cmake ..
$ make
```

## 运行

- 指定模型

  ```shell
  $ ./gazebo_sitl_single_run.sh -m alex_iris_realsense_d435
  ```

- 指定模型和世界

  ```shell
  $ ./gazebo_sitl_single_run.sh -m alex_iris_realsense_d435 -w baylands
  ```

  