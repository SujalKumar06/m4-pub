JUNIT_URL := https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/1.10.0/junit-platform-console-standalone-1.10.0.jar
JUNIT_JAR := libs/junit.jar

PMD_VER := 7.27.0
PMD_URL := https://github.com/pmd/pmd/releases/download/pmd_releases/$(PMD_VER)/pmd-dist-$(PMD_VER)-bin.zip
PMD_BIN := libs/pmd-bin-$(PMD_VER)/bin/pmd

SRCS := $(shell find src -name '*.java' 2>/dev/null)
TESTS := $(shell find test -name '*.java' 2>/dev/null)

.PHONY: deps build test clean pmd

deps: $(JUNIT_JAR)

$(JUNIT_JAR):
	@mkdir -p libs
	@curl -sSL -o $@ $(JUNIT_URL)

build: deps
	@mkdir -p build
	javac --release 17 -d build -cp $(JUNIT_JAR) $(SRCS) $(TESTS)

test: build
	java -jar $(JUNIT_JAR) --class-path build --scan-class-path

$(PMD_BIN):
	@mkdir -p libs
	@curl -sSL -o libs/pmd.zip $(PMD_URL)
	@unzip -q -o libs/pmd.zip -d libs
	@rm libs/pmd.zip

pmd: $(PMD_BIN)
	$(PMD_BIN) check -d src -R pmd-rules.xml -f text --no-cache --no-fail-on-violation

clean:
	rm -rf build libs