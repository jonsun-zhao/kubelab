// stole from https://github.com/dhoomakethu/stress/blob/master/utils/stress_cpu.go

package stress

import (
	"fmt"
	"os"
	"time"

	"github.com/shirou/gopsutil/process"
)

type cpuLoadGenerator struct {
	controller *cpuLoadController
	monitor    *cpuLoadMonitor
	duration   time.Duration
	startTime  time.Time
}

type cpuLoadController struct {
	running              bool
	samplingInterval     time.Duration
	sleepTime            time.Duration
	cpuTarget            float64
	currentCPULoad       float64
	integralConstant     float64
	proportionalConstant float64
	integralError        float64
	proportionalError    float64
	lastSampledTime      time.Time
}

type cpuLoadMonitor struct {
	samplingInterval time.Duration
	sample           float64
	cpu              float64
	running          bool
	alpha            float64
}

func newCPULoadGenerator(controller *cpuLoadController, monitor *cpuLoadMonitor, duration time.Duration) *cpuLoadGenerator {
	return &cpuLoadGenerator{controller: controller, monitor: monitor,
		duration: duration * time.Second, startTime: time.Now().Local()}
}

func newCPULoadController(samplingInterval time.Duration, cpuTarget float64) *cpuLoadController {
	return &cpuLoadController{
		running:              false,
		samplingInterval:     samplingInterval,
		sleepTime:            0.0 * time.Millisecond,
		cpuTarget:            cpuTarget,
		currentCPULoad:       0,
		integralConstant:     -1.0,
		proportionalConstant: -0.5,
		integralError:        0,
		proportionalError:    0,
		lastSampledTime:      time.Now().Local()}
}

func newCPULoadMonitor(cpu float64, interval time.Duration) *cpuLoadMonitor {
	return &cpuLoadMonitor{
		samplingInterval: interval,
		sample:           0,
		cpu:              cpu,
		running:          false,
		alpha:            0.1}
}

// Monitor

func getCPULoad(monitor *cpuLoadMonitor) float64 {
	return monitor.cpu
}

func startCPUMonitor(monitor *cpuLoadMonitor) {
	monitor.running = true
	go runCPUMonitor(monitor)
}

func stopCPUMonitor(monitor *cpuLoadMonitor) {
	monitor.running = false
}

func runCPUMonitor(monitor *cpuLoadMonitor) {
	pid := os.Getpid()
	process, _ := process.NewProcess(int32(pid))
	for monitor.running {
		monitor.sample, _ = process.CPUPercent()
		monitor.cpu = monitor.alpha*monitor.sample + (1-monitor.alpha)*monitor.cpu
		time.Sleep(monitor.samplingInterval)
	}

}

//Controller

func getSleepTime(controller *cpuLoadController) time.Duration {
	return controller.sleepTime
}

func getCPUTarget(controller *cpuLoadController) float64 {
	return controller.cpuTarget
}

func setCPU(controller *cpuLoadController, cpu float64) {
	controller.currentCPULoad = cpu
}

func setCPUTarget(controller *cpuLoadController, target float64) {
	controller.cpuTarget = target
}

func startCPULoadController(controller *cpuLoadController) {
	controller.running = true
	go runCPULoadController(controller)
}
func stopCPULoadController(controller *cpuLoadController) {
	controller.running = false
}

func runCPULoadController(controller *cpuLoadController) {
	// fmt.Printf("Running controller")
	for controller.running {
		time.Sleep(controller.samplingInterval)
		// fmt.Printf("Current CPU load %f, Cpu target: %f\n" ,controller.currentCPULoad, controller.cpuTarget)
		controller.proportionalError = controller.cpuTarget - controller.currentCPULoad*0.01
		// fmt.Printf( "proportional error %f\n" ,controller.proportionalError)
		timeNow := time.Now().Local()
		samplingInterval := time.Since(controller.lastSampledTime)
		// fmt.Printf( "new sample interval %s\n" ,samplingInterval.String())
		controller.integralError += controller.proportionalError * float64(samplingInterval) / 1000000000
		// fmt.Printf( "integral error %f\n" ,controller.integralError)
		controller.lastSampledTime = timeNow
		calSleep := (controller.proportionalConstant * controller.proportionalError) + (controller.integralConstant * controller.integralError)
		calSleep *= 1000
		// fmt.Println("New Sleep  time %f" ,calSleep)
		controller.sleepTime = time.Duration(calSleep) * time.Millisecond

		if calSleep < 0 {
			controller.sleepTime = 0
			controller.integralError -= controller.proportionalError * float64(samplingInterval) / 1000000000
			// fmt.Println("integral error after correction %f" ,controller.integralError)
		}
	}
}

// Actuator
func runCPULoader(actuator *cpuLoadGenerator) time.Duration {
	sleepTime := 1 * time.Second
	for time.Since(actuator.startTime) <= actuator.duration {
		timeNow := time.Now().Local()
		interval := 10 * time.Millisecond

		for time.Since(timeNow) < interval {
			pr := 213123.0
			pr *= pr
			pr = +1

		}
		setCPU(actuator.controller, getCPULoad(actuator.monitor))
		sleepTime = getSleepTime(actuator.controller)
		time.Sleep(sleepTime) //controller actuation

	}
	return sleepTime

}

func stressCPU(sampleInterval time.Duration, cpuload float64, duration float64, cpu int) {
	controller := newCPULoadController(sampleInterval, cpuload)
	monitor := newCPULoadMonitor(float64(cpu), sampleInterval)

	actuator := newCPULoadGenerator(controller, monitor, time.Duration(duration))
	startCPULoadController(controller)
	startCPUMonitor(monitor)

	runCPULoader(actuator)
	stopCPULoadController(controller)
	stopCPUMonitor(monitor)

	defer fmt.Println("cpu stress finished")
}
