from setuptools import setup, find_packages

setup(
    name="queuectl",
    version="1.0.0",
    description="A CLI-based background job queue system with worker processes, retry logic, and Dead Letter Queue",
    author="Your Name",
    packages=find_packages(),
    install_requires=[
        "click>=8.0.0",
    ],
    entry_points={
        "console_scripts": [
            "queuectl=queuectl.cli:cli",
        ],
    },
    python_requires=">=3.8",
)