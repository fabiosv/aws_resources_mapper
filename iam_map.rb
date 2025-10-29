require 'json'

class AWSIAMMap
  def initialize
      
  end

  def list_all_roles
    roles = `aws iam list-roles --output json`
    return roles['Roles']
  end

  def list_all_policies
    policies = `aws iam list-policies --output json`
    policies['Policies']
  end

  def get_last_role_activity(role_arn)
    job = `aws iam generate-service-last-accessed-details --output json --arn #{role_arn}`
    job_id = job['JobId']
    details = `aws iam get-service-last-accessed-details --output json --job-id #{job_id}`
    return details['ServicesLastAccessed']
  end

  def get_attached_role_policies(role_name)
    attached = `aws iam list-attached-role-policies --role-name #{role_name} --output json`
    return attached['AttachedPolicies']
  end

  def build_roles_map
    roles = self.list_all_roles

    roles.map do |role|
      role_name = role['RoleName']
      role_arn = role['Arn']
      role['ServicesLastAccessed'] = self.get_last_role_activity(role_arn)
      role['AttachedPolicies'] = self.get_attached_role_policies(role_name)
      role
    end
  end
end