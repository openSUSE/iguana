use linked_hash_map::LinkedHashMap;
use log::info;
/// Implementation of Iguana workflow parsing
use serde::Deserialize;

use std::collections::HashMap;
use std::option::Option;

mod job;

/// Container
#[derive(Deserialize)]
pub struct Container {
    pub image: String,
    pub env: Option<HashMap<String, String>>,
    pub volumes: Option<Vec<String>>,
}

/// Step
#[derive(Deserialize)]
pub struct Step {
    name: Option<String>,
    run: String,
    uses: Option<String>,
    with: Option<String>,
    env: Option<HashMap<String, String>>,
}
/// Job
#[derive(Deserialize)]
pub struct Job {
    container: Container,
    services: Option<HashMap<String, Container>>,
    needs: Option<Vec<String>>,
    steps: Option<Vec<Step>>,
    #[serde(default)]
    continue_on_error: bool,
}

/// Workflow
#[derive(Deserialize)]
pub struct Workflow {
    name: Option<String>,
    description: Option<String>,
    jobs: LinkedHashMap<String, Job>,
    env: Option<HashMap<String, String>>,
}

pub struct WorkflowOptions {
    pub dry_run: bool,
    pub debug: bool,
    pub privileged: bool,
}

pub fn do_workflow(workflow: String, opts: &WorkflowOptions) -> Result<(), String> {
    let yaml_result: Result<Workflow, _> = serde_yaml::from_str(&workflow);

    let yaml = match yaml_result {
        Ok(r) => r,
        Err(e) => {
            return Err(format!("Unable to parse provided workflow file: {}", e));
        }
    };

    info!("Loaded {}", yaml.name.unwrap_or_else(|| "control file".to_owned()));

    let jobs = yaml.jobs;

    if jobs.is_empty() {
        return Err("No jobs in control file!".to_owned());
    }

    let job_results = job::do_jobs(jobs, HashMap::new(), &yaml.env, opts);

    match job_results {
        Ok(_) => info!("Workflow ran successfully"),
        Err(e) => return Err(e),
    };
    Ok(())
}
