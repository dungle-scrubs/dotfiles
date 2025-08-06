import type { 
  ContentMergeResult, 
  SyncMetadata,
  WindsurfFrontmatter,
  WindsurfRuleFrontmatter,
  WindsurfTriggerType,
  WindsurfWorkflowFrontmatter
} from '../types/sync';
import { DEFAULT_WINDSURF_TRIGGER, isWorkflowFrontmatter, isRuleFrontmatter } from '../types/sync';

interface ContentSection {
  readonly content: string;
  readonly heading: string;
}

export class ContentMerger {
  mergeClaudeToWindsurf(
    claudeContent: string, 
    metadata: SyncMetadata,
    existingWindsurfContent?: string,
    isWorkflow: boolean = false
  ): ContentMergeResult {
    try {
      const sections = this.extractSections(claudeContent);
      
      // Extract existing frontmatter from the Windsurf file if available
      const existingFrontmatter = existingWindsurfContent 
        ? this.extractFrontmatter(existingWindsurfContent).frontmatter 
        : null;
      
      const windsurfContent = this.convertToWindsurfFormat(sections, metadata, existingFrontmatter, isWorkflow);
      
      return {
        mergedContent: windsurfContent,
        success: true
      };
    } catch (error) {
      return {
        mergedContent: '',
        success: false
      };
    }
  }

  mergeWindsurfToClaude(
    windsurfContent: string, 
    metadata: SyncMetadata
  ): ContentMergeResult {
    try {
      const contentWithoutFrontmatter = this.removeFrontmatter(windsurfContent);
      const sections = this.extractSections(contentWithoutFrontmatter);
      const claudeContent = this.convertToClaudeFormat(sections, metadata);
      
      return {
        mergedContent: claudeContent,
        success: true
      };
    } catch (error) {
      return {
        mergedContent: '',
        success: false
      };
    }
  }

  mergeBidirectional(
    sourceContent: string,
    targetContent: string,
    sourceMetadata: SyncMetadata,
    preferSource: boolean = true
  ): ContentMergeResult {
    try {
      const sourceSections = this.extractSections(sourceContent);
      const targetSections = this.extractSections(targetContent);
      
      const mergedSections: ContentSection[] = [];
      const sourceHeadings = new Set(sourceSections.map(s => s.heading));
      
      // Add all source sections
      mergedSections.push(...sourceSections);
      
      // Add target sections that don't exist in source
      for (const targetSection of targetSections) {
        if (!sourceHeadings.has(targetSection.heading)) {
          mergedSections.push(targetSection);
        }
      }
      
      // Sort sections alphabetically by heading
      mergedSections.sort((a, b) => a.heading.localeCompare(b.heading));
      
      const mergedContent = this.combineSections(mergedSections, sourceMetadata);
      
      return {
        mergedContent,
        success: true
      };
    } catch (error) {
      return {
        mergedContent: sourceContent, // Fallback to source
        success: false
      };
    }
  }

  private extractSections(content: string): ContentSection[] {
    const sections: ContentSection[] = [];
    const lines = content.split('\n');
    let currentHeading = '';
    let currentContent: string[] = [];
    let hasHeadings = false;
    
    for (const line of lines) {
      const headingMatch = line.match(/^(#{1,6})\s+(.+)$/);
      
      if (headingMatch) {
        hasHeadings = true;
        // Save previous section if it exists
        if (currentHeading && currentContent.length > 0) {
          sections.push({
            content: currentContent.join('\n').trim(),
            heading: currentHeading
          });
        }
        
        // Start new section
        currentHeading = headingMatch[2].trim();
        currentContent = [];
      } else if (currentHeading) {
        // Skip sync metadata comments
        if (!line.startsWith('<!-- Last synced:') && 
            !line.startsWith('<!-- Source:') && 
            !line.startsWith('<!-- Sync version:')) {
          currentContent.push(line);
        }
      } else if (!hasHeadings) {
        // If we haven't found any headings yet, collect all content
        if (!line.startsWith('<!-- Last synced:') && 
            !line.startsWith('<!-- Source:') && 
            !line.startsWith('<!-- Sync version:')) {
          currentContent.push(line);
        }
      }
    }
    
    // Add final section
    if (currentHeading && currentContent.length > 0) {
      sections.push({
        content: currentContent.join('\n').trim(),
        heading: currentHeading
      });
    }
    
    // If no headings were found, create a default section with all content
    if (!hasHeadings && currentContent.length > 0) {
      const allContent = currentContent.join('\n').trim();
      if (allContent) {
        sections.push({
          content: allContent,
          heading: 'Content'
        });
      }
    }
    
    return sections;
  }

  private convertToWindsurfFormat(
    sections: ContentSection[], 
    metadata: SyncMetadata,
    existingFrontmatter?: WindsurfFrontmatter | null,
    isWorkflow: boolean = false
  ): string {
    const frontmatter = isWorkflow 
      ? this.createWorkflowFrontmatter(existingFrontmatter as WindsurfWorkflowFrontmatter)
      : this.createRuleFrontmatter(existingFrontmatter as WindsurfRuleFrontmatter);
    const metadataHeader = this.formatSyncMetadata(metadata);
    const windsurfSections = sections.map(section => {
      return this.adaptSectionForWindsurf(section);
    });
    
    return [
      frontmatter,
      '',
      metadataHeader,
      '',
      ...windsurfSections
    ].join('\n');
  }

  private convertToClaudeFormat(
    sections: ContentSection[], 
    metadata: SyncMetadata
  ): string {
    const metadataHeader = this.formatSyncMetadata(metadata);
    const claudeSections = sections.map(section => {
      return this.adaptSectionForClaude(section);
    });
    
    return [
      metadataHeader,
      '',
      ...claudeSections
    ].join('\n');
  }

  private adaptSectionForWindsurf(section: ContentSection): string {
    // Convert Claude-style sections to Windsurf rules format
    const adaptedHeading = this.convertHeadingForWindsurf(section.heading);
    const adaptedContent = this.convertContentForWindsurf(section.content);
    
    return `## ${adaptedHeading}\n\n${adaptedContent}`;
  }

  private adaptSectionForClaude(section: ContentSection): string {
    // Convert Windsurf-style sections to Claude format
    const adaptedHeading = this.convertHeadingForClaude(section.heading);
    const adaptedContent = this.convertContentForClaude(section.content);
    
    return `## ${adaptedHeading}\n\n${adaptedContent}`;
  }

  private convertHeadingForWindsurf(heading: string): string {
    // Map common Claude sections to Windsurf equivalents
    const mappings: Record<string, string> = {
      'Commands': 'Workflows',
      'Project Structure': 'Architecture Guidelines',
      'Setup': 'Project Setup Rules',
      'Tech Stack': 'Technology Rules'
    };
    
    return mappings[heading] || heading;
  }

  private convertHeadingForClaude(heading: string): string {
    // Map common Windsurf sections back to Claude equivalents
    const mappings: Record<string, string> = {
      'Architecture Guidelines': 'Project Structure', 
      'Project Setup Rules': 'Setup',
      'Technology Rules': 'Tech Stack',
      'Workflows': 'Commands'
    };
    
    return mappings[heading] || heading;
  }

  private convertContentForWindsurf(content: string): string {
    // Convert Claude-specific syntax to Windsurf rules format
    return content
      .replace(/^- /gm, '* ') // Convert bullet points
      .replace(/`([^`]+)`/g, '**$1**'); // Convert inline code to bold
  }

  private convertContentForClaude(content: string): string {
    // Convert Windsurf-specific syntax to Claude format
    return content
      .replace(/^\* /gm, '- ') // Convert bullet points back
      .replace(/\*\*([^*]+)\*\*/g, '`$1`'); // Convert bold back to inline code
  }

  private combineSections(
    sections: ContentSection[], 
    metadata: SyncMetadata
  ): string {
    const metadataHeader = this.formatSyncMetadata(metadata);
    const sectionContent = sections.map(section => 
      `## ${section.heading}\n\n${section.content}`
    );
    
    return [
      metadataHeader,
      '',
      ...sectionContent
    ].join('\n\n');
  }

  private formatSyncMetadata(metadata: SyncMetadata): string {
    return `<!-- Last synced: ${metadata.lastSyncTime.toISOString()} -->
<!-- Source: ${metadata.sourceFile} -->
<!-- Sync version: ${metadata.syncVersion} -->`;
  }

  removeFrontmatter(content: string): string {
    // Check if content starts with YAML frontmatter
    if (!content.startsWith('---')) {
      return content;
    }

    const lines = content.split('\n');
    let endFrontmatterIndex = -1;

    // Find the closing --- (skip the first line which is the opening ---)
    for (let i = 1; i < lines.length; i++) {
      if (lines[i].trim() === '---') {
        endFrontmatterIndex = i;
        break;
      }
    }

    if (endFrontmatterIndex === -1) {
      // No closing ---, treat as regular content
      return content;
    }

    // Return content after the frontmatter
    return lines.slice(endFrontmatterIndex + 1).join('\n').trim();
  }

  private createRuleFrontmatter(
    existingFrontmatter?: WindsurfRuleFrontmatter
  ): string {
    const trigger = existingFrontmatter?.trigger || DEFAULT_WINDSURF_TRIGGER;
    const lines = [`---`, `trigger: ${trigger}`];
    
    // Add description if it exists (always optional)
    if (existingFrontmatter?.description) {
      lines.push(`description: ${existingFrontmatter.description}`);
    } else if (trigger === 'model_decision' || trigger === 'always_on') {
      // For AI-triggered rules without description, add a placeholder instruction
      lines.push(`description: "🤖 AI: Please add a clear description of when this rule should apply"`);
    }
    
    // Add globs if it exists (always optional)
    if (existingFrontmatter?.globs) {
      lines.push(`globs: ${existingFrontmatter.globs}`);
    }
    
    lines.push(`---`);
    
    return lines.join('\n');
  }

  private createWorkflowFrontmatter(
    existingFrontmatter?: WindsurfWorkflowFrontmatter
  ): string {
    const lines = [`---`];
    
    // Description is required for workflows
    if (existingFrontmatter?.description) {
      lines.push(`description: ${existingFrontmatter.description}`);
    } else {
      // For workflows without description, add a placeholder instruction
      lines.push(`description: "🤖 AI: Please add a clear description of what this workflow does"`);
    }
    
    lines.push(`---`);
    
    return lines.join('\n');
  }

  private extractFrontmatter(content: string): { frontmatter: WindsurfFrontmatter | null; content: string } {
    if (!content.startsWith('---')) {
      return { frontmatter: null, content };
    }

    const lines = content.split('\n');
    let endFrontmatterIndex = -1;

    for (let i = 1; i < lines.length; i++) {
      if (lines[i].trim() === '---') {
        endFrontmatterIndex = i;
        break;
      }
    }

    if (endFrontmatterIndex === -1) {
      return { frontmatter: null, content };
    }

    const frontmatterLines = lines.slice(1, endFrontmatterIndex);
    const remainingContent = lines.slice(endFrontmatterIndex + 1).join('\n').trim();

    // Parse YAML frontmatter
    let trigger: WindsurfTriggerType | undefined;
    let description: string | undefined;
    let globs: string | undefined;
    
    for (const line of frontmatterLines) {
      const colonIndex = line.indexOf(':');
      if (colonIndex === -1) continue;
      
      const key = line.substring(0, colonIndex).trim();
      const value = line.substring(colonIndex + 1).trim().replace(/^"(.*)"$/, '$1'); // Remove quotes
      
      if (key === 'trigger') {
        trigger = value as WindsurfTriggerType;
      } else if (key === 'description') {
        description = value;
      } else if (key === 'globs') {
        globs = value;
      }
    }

    const validFrontmatter: WindsurfFrontmatter | null = trigger 
      ? { trigger, description, globs } as WindsurfRuleFrontmatter
      : description 
        ? { description } as WindsurfWorkflowFrontmatter
        : null;

    return { frontmatter: validFrontmatter, content: remainingContent };
  }

  /**
   * Converts AI command files to Claude global command format
   */
  mergeAiCommandToClaude(
    aiCommandContent: string,
    metadata: SyncMetadata
  ): ContentMergeResult {
    try {
      // AI commands are already in a Claude-compatible format
      // Just add sync metadata
      const metadataHeader = this.formatSyncMetadata(metadata);
      const mergedContent = [metadataHeader, '', aiCommandContent.trim()].join('\n');
      
      return {
        mergedContent,
        success: true
      };
    } catch (error) {
      return {
        mergedContent: '',
        success: false
      };
    }
  }

  /**
   * Converts AI command files to Windsurf global workflow format
   */
  mergeAiCommandToWindsurf(
    aiCommandContent: string,
    metadata: SyncMetadata,
    existingWindsurfContent?: string
  ): ContentMergeResult {
    try {
      // Extract existing frontmatter if available
      const existingFrontmatter = existingWindsurfContent 
        ? this.extractFrontmatter(existingWindsurfContent).frontmatter as WindsurfWorkflowFrontmatter
        : null;

      // Create workflow frontmatter (description is required)
      const frontmatter = this.createWorkflowFrontmatter(existingFrontmatter);
      
      // Add sync metadata and content
      const metadataHeader = this.formatSyncMetadata(metadata);
      const mergedContent = [
        frontmatter,
        '',
        metadataHeader,
        '',
        aiCommandContent.trim()
      ].join('\n');
      
      return {
        mergedContent,
        success: true
      };
    } catch (error) {
      return {
        mergedContent: '',
        success: false
      };
    }
  }

  /**
   * Converts Claude global command back to AI command format
   */
  mergeClaudeToAiCommand(
    claudeCommandContent: string,
    metadata: SyncMetadata
  ): ContentMergeResult {
    try {
      // Remove sync metadata and keep the content
      const cleanContent = this.removeSyncMetadata(claudeCommandContent);
      const metadataHeader = this.formatSyncMetadata(metadata);
      const mergedContent = [metadataHeader, '', cleanContent.trim()].join('\n');
      
      return {
        mergedContent,
        success: true
      };
    } catch (error) {
      return {
        mergedContent: '',
        success: false
      };
    }
  }

  /**
   * Converts Windsurf global workflow back to AI command format
   */
  mergeWindsurfToAiCommand(
    windsurfWorkflowContent: string,
    metadata: SyncMetadata
  ): ContentMergeResult {
    try {
      // Remove frontmatter and sync metadata, keep the content
      const contentWithoutFrontmatter = this.removeFrontmatter(windsurfWorkflowContent);
      const cleanContent = this.removeSyncMetadata(contentWithoutFrontmatter);
      const metadataHeader = this.formatSyncMetadata(metadata);
      const mergedContent = [metadataHeader, '', cleanContent.trim()].join('\n');
      
      return {
        mergedContent,
        success: true
      };
    } catch (error) {
      return {
        mergedContent: '',
        success: false
      };
    }
  }

  private removeSyncMetadata(content: string): string {
    const lines = content.split('\n');
    const filteredLines = lines.filter(line => 
      !line.startsWith('<!-- Last synced:') &&
      !line.startsWith('<!-- Source:') &&
      !line.startsWith('<!-- Sync version:')
    );
    
    return filteredLines.join('\n').trim();
  }
}